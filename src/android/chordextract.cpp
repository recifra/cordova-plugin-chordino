#include <jni.h>
#include <string>

#include "vamp-hostsdk/PluginInputDomainAdapter.h"
#include "vamp-hostsdk/PluginBufferingAdapter.h"

#include "nnls-chroma/Chordino.h"

#include <iostream>
#include <string>

using namespace std;
using namespace Vamp;
using namespace Vamp::HostExt;

extern "C" JNIEXPORT jlong JNICALL
Java_com_recifra_chordino_Extractor_initializePlugin(
        JNIEnv* env,
        jobject /* this */,
        jfloat samplerate,
        jsize blocksize
        ) {
    auto *chordino = new Chordino(samplerate);
    auto *ia = new PluginInputDomainAdapter(chordino);
    ia->setProcessTimestampMethod(PluginInputDomainAdapter::ShiftData);
    auto *adapter = new PluginBufferingAdapter(ia);

    // Plugin requires 1 channel (we will mix after)
    if (!adapter->initialise(1, blocksize, blocksize)) {
        jclass jcls = env->FindClass("java/lang/ExceptionInInitializerError");
        env->ThrowNew(jcls, "Failed to initialise Chordino adapter");
        return 0;
    }
    return (jlong) adapter;
}

extern "C" JNIEXPORT void JNICALL
Java_com_recifra_chordino_Extractor_releasePlugin(
        JNIEnv* /* env */,
        jobject /* this */,
        jlong lpAdapter
        ) {
    auto *adapter = (PluginBufferingAdapter *) lpAdapter;
    delete adapter;
}

extern "C" JNIEXPORT void JNICALL
Java_com_recifra_chordino_Extractor_resetProcess(JNIEnv* env,
                                                 jobject /* this */,
                                                 jlong lpAdapter
) {
    auto *adapter = (PluginBufferingAdapter *) lpAdapter;
    adapter->reset();
}

extern "C" JNIEXPORT void JNICALL
Java_com_recifra_chordino_Extractor_processBuffer(JNIEnv* env,
                                                  jobject /* this */,
                                                  jlong lpAdapter,
                                                  jfloatArray mixbufArray,
                                                  jlong milliseconds
) {
    jfloat *mixbuf = env->GetFloatArrayElements(mixbufArray, nullptr);
    auto *adapter = (PluginBufferingAdapter *) lpAdapter;

    RealTime timestamp = RealTime::fromMilliseconds((int) milliseconds);

    // feed to plugin: can just take address of buffer, as only one channel
    adapter->process(&mixbuf, timestamp);
    env->ReleaseFloatArrayElements(mixbufArray, mixbuf, 0);
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_recifra_chordino_Extractor_getResult(JNIEnv* env,
                                                     jobject /* this */,
                                                     jlong lpAdapter
                                                     ) {
    auto *adapter = (PluginBufferingAdapter *) lpAdapter;
    int chordFeatureNo = -1;
    Plugin::OutputList outputs = adapter->getOutputDescriptors();
    for (int i = 0; i < int(outputs.size()); ++i)
    {
        if (outputs[i].identifier == "simplechord")
        {
            chordFeatureNo = i;
            break;
        }
    }
    if (chordFeatureNo < 0)
    {
        jclass jcls = env->FindClass("java/lang/Exception");
        env->ThrowNew(jcls, "Failed to identify chords output");
        return nullptr;
    }
    // features at end of processing (actually Chordino does all its work here)
    Plugin::FeatureSet fs = adapter->getRemainingFeatures();
    Plugin::FeatureList& chordFeatures = fs[chordFeatureNo];
    jobjectArray result = env->NewObjectArray((int) chordFeatures.size(),
                                              env->FindClass("android/util/Pair"),
                                              nullptr);
    for (int i = 0; i < (int)chordFeatures.size(); ++i)
    {
        jclass pairClass = env->FindClass("android/util/Pair");
        jmethodID pairConstructor = env->GetMethodID(pairClass, "<init>",
                                                     "(Ljava/lang/Object;Ljava/lang/Object;)V");
        jstring title = env->NewStringUTF(chordFeatures[i].label.c_str());
        jclass floatClass = env->FindClass("java/lang/Float");
        jobject timestampObj = env->NewObject(
                floatClass,
                env->GetMethodID(floatClass, "<init>", "(F)V"),
                static_cast<jfloat>(chordFeatures[i].timestamp.sec + (float) chordFeatures[i].timestamp.msec() / 1000.f)
                );
        jobject pair = env->NewObject(pairClass, pairConstructor, title, timestampObj);
        env->SetObjectArrayElement(result, i, pair);
    }
    return result;
}
