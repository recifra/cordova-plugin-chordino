package com.recifra.chordino

import android.util.Pair

class Extractor {
    private var lpAdapter: Long = 0

    fun initialize(samplerate: Float, blocksize: Int) {
        if (lpAdapter != 0L) {
            throw Exception("The library Extractor was already initialized")
        }
        lpAdapter = initializePlugin(samplerate, blocksize)
    }

    fun release() {
        if (lpAdapter == 0L) {
            return
        }
        releasePlugin(lpAdapter)
        lpAdapter = 0L
    }

    fun reset() {
        require()
        resetProcess(lpAdapter)
    }

    fun process(buffer: FloatArray, milliseconds: Long) {
        require()
        processBuffer(lpAdapter, buffer, milliseconds)
    }

    fun result(): Array<Pair<String, Float>> {
        require()
        return getResult(lpAdapter)
    }

    private fun require() {
        if (lpAdapter != 0L) {
            return
        }
        throw Exception("The library Extractor was not initialized")
    }

    private external fun initializePlugin(samplerate: Float, blocksize: Int): Long

    private external fun processBuffer(
        lp: Long,
        mixbuf: FloatArray,
        milliseconds: Long,
    )

    private external fun getResult(
        lp: Long,
    ): Array<Pair<String, Float>>

    private external fun resetProcess(lp: Long)

    private external fun releasePlugin(lp: Long)

    companion object {
        init {
            System.loadLibrary("chordextract")
        }
    }
}
