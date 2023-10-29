import AVFoundation
import Chordino

class AudioCapture {
    private var sampleAudioBitRate: Int
    private var bufferLength: Int
    private var audioEngine: AVAudioEngine!
    private var mic: AVAudioInputNode!
    private var micTapped = false

    init(sampleAudioBitRate: Int, bufferLength: Int) {
        self.sampleAudioBitRate = sampleAudioBitRate
        self.bufferLength = bufferLength
        audioEngine = AVAudioEngine()
        mic = audioEngine.inputNode
    }

    func stop() {
        audioEngine.stop()
        audioEngine.reset()
    }

    func run(closure: @escaping (String, Float) -> Void) {
        if micTapped {
            mic.removeTap(onBus: 0)
            micTapped = false
            return
        }
        let extractor = ChordinoWrapper(samplerate: Float(sampleAudioBitRate))
        extractor!.prepare(bufferLength)
        let micFormat = mic.inputFormat(forBus: 0)
        let startTime = getCurrentMillis()
        var lastChangeTime = getCurrentMillis()
        var lastChord = ""
        mic.installTap(onBus: 0, bufferSize: UInt32(bufferLength), format: micFormat) { (buffer, when) in
            let sampleData = buffer.floatChannelData![0]
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
        guard !audioEngine.isRunning else {
            return
        }

        do {
            try audioEngine.start()
        } catch { }
    }
}
