package com.recifra.cordova.plugin.chordino

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import com.recifra.chordino.AudioCapture
import com.recifra.chordino.Extractor
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.apache.cordova.PermissionHelper
import org.apache.cordova.PluginResult
import org.json.JSONArray
import org.json.JSONObject
import kotlin.concurrent.thread

/**
 * This class echoes a string called from JavaScript.
 */
class Chordino : CordovaPlugin() {
    private var audioCapture: AudioCapture? = null
    private var samplerate: Int = 0
    private var blocksize: Int = 0
    private var sensitivity: Float = 0.12f
    private lateinit var savedCallbackContext: CallbackContext

    override fun execute(
        action: String,
        args: JSONArray,
        callbackContext: CallbackContext
    ): Boolean {
        val initialized = audioCapture != null
        if (action == "start" && initialized) {
            stop()
        }
        if (action == "start") {
            samplerate = args.getInt(0)
            blocksize = args.getInt(1)
            sensitivity = args.optDouble(2, 0.12).toFloat()
            savedCallbackContext = callbackContext
            audioCapture = AudioCapture(samplerate, blocksize)
            cordova.threadPool.execute {
                requestPermissionAndRun()
            }
            return true
        }
        if (action == "stop" && !initialized) {
            callbackContext.success(0)
            return true
        }
        if (action == "stop") {
            stop()
            callbackContext.success(1)
            return true
        }
        if (action == "sensitivity") {
            sensitivity = args.getDouble(0).toFloat()
            callbackContext.success(1)
            return true
        }
        return false
    }

    override fun onReset() {
        stop()
    }

    override fun onPause(multitasking: Boolean) {
        stop()
    }

    private fun stop() {
        audioCapture?.stop()
        audioCapture = null
    }

    private fun startCapture() {
        Log.d("Chordino", "startCapture")
        Thread {
            var lastChord = ""
            var lastChangeTime = System.currentTimeMillis()
            val startTime = System.currentTimeMillis()
            val extractor = Extractor()
            extractor.initialize(samplerate.toFloat(), blocksize)

            audioCapture?.run({ buffer: FloatArray ->
                buffer.forEachIndexed({ index: Int, value: Float -> buffer[index] = value * sensitivity })
                extractor.process(buffer, System.currentTimeMillis() - startTime)
                val result = extractor.result()
                if (result.size <= 2 && System.currentTimeMillis() - lastChangeTime > 250) {
                    lastChangeTime = System.currentTimeMillis()
                }
                if (result.size > 2) {
                    extractor.reset()
                    lastChangeTime = System.currentTimeMillis()
                }
                if (result.size > 2 && lastChord != result[1].first) {
                    lastChord = result[1].first
                    Log.d(
                        "Chordino",
                        "Chord: " + result[1].first + " | " + String.format(
                            "%.03f",
                            result[1].second
                        )
                    )
                    val message = JSONObject()
                    message.put("chord", result[1].first)
                    message.put("time", result[1].second)
                    val pluginResult = PluginResult(PluginResult.Status.OK, message)
                    pluginResult.keepCallback = true
                    savedCallbackContext.sendPluginResult(pluginResult)
                }
            }, { error: String ->
                Log.e("Chordino", error)
                savedCallbackContext.error(error)
            })
            extractor.release()
        }.start()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>?,
        grantResults: IntArray?
    ) {
        if (grantResults == null) {
            return
        }
        for (result in grantResults) {
            if (result == PackageManager.PERMISSION_DENIED) {
                savedCallbackContext.error("Audio permission denied")
                Log.d("Chordino", "RECORD_AUDIO PERMISSION GRANTED")
                return
            }
        }
        startCapture()
    }

    private fun requestPermissionAndRun() {
        Log.d("Chordino", "requestPermissionAndRun")

        if (PermissionHelper.hasPermission(this, Manifest.permission.RECORD_AUDIO)) {
            startCapture()
        } else {
            PermissionHelper.requestPermission(this, 0, Manifest.permission.RECORD_AUDIO)
        }
    }
}
