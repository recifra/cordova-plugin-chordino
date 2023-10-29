import AVFoundation
import Chordino

@objc(Chordino) class Chordino: CDVPlugin {
    var audioCapture: AudioCapture?
    var callbackId: String?

    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        let samplerate = command.argument(at: 0)
        let blocksize = command.argument(at: 1)
        let initialized = audioCapture != nil
        if (initialized) {
            stopAudioCapture()
        }
        callbackId = command.callbackId
        audioCapture = AudioCapture(sampleAudioBitRate: samplerate as! Int, bufferLength: blocksize as! Int)
        requestPermissionAndRun()
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

    private func stopAudioCapture() {
        audioCapture?.stop()
        audioCapture = nil
    }

    private func requestPermissionAndRun() {
        switch AVAudioSession.sharedInstance().recordPermission() {
            case AVAudioSessionRecordPermission.granted:
                NSLog("Permission granted")
                runCapture()
            case AVAudioSessionRecordPermission.denied:
                NSLog("Permission denied")
            case AVAudioSessionRecordPermission.undetermined:
                NSLog("Request permission here")
                AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                    if (granted) {
                        NSLog("Permission granted after prompt")
                        self.runCapture()
                    } else {
                        NSLog("Permission denied after prompt")
                    }
                })
            @unknown default:
                NSLog("Unknown case")
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
