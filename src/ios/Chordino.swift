import AVFoundation
import Chordino

@objc(Chordino) class Chordino: CDVPlugin {
    var audioCapture: AudioCapture?
    var callbackId: String?

    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        let samplerate = command.argument(at: 0)
        let blocksize = command.argument(at: 1)
        let sensitivity = command.argument(at: 2)
        let initialized = audioCapture != nil
        if (initialized) {
            stopAudioCapture()
        }
        callbackId = command.callbackId
        audioCapture = AudioCapture(
            sampleAudioBitRate: samplerate as! Int,
            bufferLength: blocksize as! Int,
            sensitivity: sensitivity as! Double
        )
        commandDelegate.run(inBackground: { [self] in
            requestPermissionAndRun()
        })
    }

    @objc(stop:)
    func stop(command: CDVInvokedUrlCommand) {
        let initialized = audioCapture != nil
        if (initialized) {
            stopAudioCapture()
        }
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: initialized)
        commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(sensitivity:)
    func sensitivity(command: CDVInvokedUrlCommand) {
        let initialized = audioCapture != nil
        let sensitivity = command.argument(at: 0)
        if (initialized) {
            audioCapture?.sensitivity = Float(sensitivity as! Double)
        }
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: initialized)
        commandDelegate.send(result, callbackId: command.callbackId)
    }

    private func stopAudioCapture() {
        commandDelegate.run(inBackground: { [self] in
            audioCapture?.stop()
            audioCapture = nil
        })
    }

    private func requestPermissionAndRun() {
        switch AVAudioSession.sharedInstance().recordPermission() {
            case AVAudioSessionRecordPermission.granted:
                NSLog("Record Permission granted")
                runCapture()
                break
            case AVAudioSessionRecordPermission.denied:
                NSLog("Record Permission denied")
            case AVAudioSessionRecordPermission.undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                    if granted {
                        NSLog("Record Permission granted")
                        self.runCapture()
                    } else {
                        NSLog("Record Permission denied")
                    }
                })
        }
    }

    private func runCapture() {
        audioCapture?.run() { (chord, time) in
            NSLog("Chord: %@ | %f", chord, time)
            let result = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: ["chord": chord, "time": time])
            result!.setKeepCallbackAs(true)
            self.commandDelegate.send(result, callbackId: self.callbackId)
        }
    }
}
