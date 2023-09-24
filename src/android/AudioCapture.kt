package com.recifra.chordino

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log

import kotlin.Unit

class AudioCapture(private var sampleAudioBitRate: Int, private var bufferLength: Int) {
    private lateinit var audioRecord: AudioRecord
    private var isAudioRecording: Boolean = false;

    fun stop() {
        isAudioRecording = false;
    }

    fun run(resultCallback: (FloatArray) -> Unit, errorCallback: (String) -> Unit) {
        var audioData: FloatArray

        try {
            /* set audio recorder parameters, and start recording */
            audioRecord =
                AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION, sampleAudioBitRate,
                    AudioFormat.CHANNEL_IN_DEFAULT, AudioFormat.ENCODING_PCM_FLOAT, bufferLength
                );
            audioData = FloatArray(bufferLength);
            audioRecord.startRecording();
            isAudioRecording = true;
            Log.d("Chordino", "audioRecord.startRecording()");
            while (isAudioRecording) {
                audioRecord.read(audioData, 0, audioData.size, AudioRecord.READ_BLOCKING);
                resultCallback(audioData);
            }
            /* encoding finish, release recorder */
            audioRecord.stop();
            audioRecord.release();
        } catch (e: SecurityException) {
            errorCallback("AudioRecord: " + e.message);
        } catch (e: Exception) {
            errorCallback("AudioCapture: " + e.message);
        } finally {
            isAudioRecording = false;
        }
    }
}