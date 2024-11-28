import AVFoundation
import Chordino

class AudioCapture {
    private var sampleAudioBitRate: Int
    private var bufferLength: Int
    public  var sensitivity: Float
    private var audioEngine: AVAudioEngine?
    private var mic: AVAudioInputNode?
    private var micTapped = false

    init(sampleAudioBitRate: Int, bufferLength: Int, sensitivity: Double) {
        self.sampleAudioBitRate = sampleAudioBitRate
        self.bufferLength = bufferLength
        self.sensitivity = Float(sensitivity)
    }

    func stop() {
        audioEngine?.stop()
        audioEngine?.reset()
    }

    func run(closure: @escaping (String, Float) -> Void) {
        if micTapped {
            mic?.removeTap(onBus: 0)
            micTapped = false
            return
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch let error as NSError {
            NSLog("AudioSession Error: %@", [error.localizedDescription])
            return
        }
        audioEngine = AVAudioEngine()
        mic = audioEngine?.inputNode
        let extractor = ChordinoWrapper(samplerate: Float(sampleAudioBitRate))
        extractor!.prepare(bufferLength)
        mic?.removeTap(onBus: 0)
        let micFormat = mic?.inputFormat(forBus: 0)
        if micFormat?.sampleRate == 0 {
            NSLog("InputFormat zero sampleRate error")
            return
        }
        let startTime = getCurrentMillis()
        var lastChangeTime = getCurrentMillis()
        var lastChord = ""
        mic?.installTap(onBus: 0, bufferSize: UInt32(bufferLength), format: micFormat) { (buffer, when) in
            let sampleData = buffer.floatChannelData![0]
            for i in 0 ..< Int(buffer.frameLength) {
                sampleData[i] *= self.sensitivity
            }
            extractor!.process(sampleData, milliseconds: Int(self.getCurrentMillis() - startTime))
            let chordList = extractor!.getResult()
            if (chordList!.count <= 2 && self.getCurrentMillis() - lastChangeTime > 250) {
                lastChangeTime = self.getCurrentMillis()
            }
            if (chordList!.count > 2) {
                extractor!.reset()
                lastChangeTime = self.getCurrentMillis()
            }
            if (chordList!.count > 2 && lastChord != (chordList![1] as! ChordItem).chord) {
                let chordItem = (chordList![1] as! ChordItem)
                lastChord = chordItem.chord
                closure(chordItem.chord, chordItem.time)
            }
        }
        micTapped = true
        startEngine()
    }

    private func getCurrentMillis()->Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func startEngine() {
        guard !audioEngine!.isRunning else {
            return
        }

        do {
            try audioEngine?.start()
        } catch { }
    }
}
