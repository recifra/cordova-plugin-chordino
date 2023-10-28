#include <string>

#include <vamp-hostsdk/PluginInputDomainAdapter.h>
#include <vamp-hostsdk/PluginBufferingAdapter.h>

#include "nnls-chroma/Chordino.h"

#include <iostream>
#include <string>
#include "chordextract.h"

using namespace std;
using namespace Vamp;
using namespace Vamp::HostExt;

ChordExtract::ChordExtract(float samplerate)
{
    auto *chordino = new Chordino(samplerate);
    auto *ia = new PluginInputDomainAdapter(chordino);
    ia->setProcessTimestampMethod(PluginInputDomainAdapter::ShiftData);
    this->adapter = new PluginBufferingAdapter(ia);
}

ChordExtract::~ChordExtract()
{
    delete this->adapter;
}

void ChordExtract::initialize(size_t blocksize)
{
    // Plugin requires 1 channel (we will mix after)
    if (!this->adapter->initialise(1, blocksize, blocksize)) {
        throw runtime_error("Failed to initialise Chordino adapter");
    }
}

void ChordExtract::process(float* bufferArray, long milliseconds)
{
    RealTime timestamp = RealTime::fromMilliseconds((int) milliseconds);
    // feed to plugin: can just take address of buffer, as only one channel
    this->adapter->process(&bufferArray, timestamp);
}

std::vector<chord_info_t> ChordExtract::getResult()
{
    int chordFeatureNo = -1;
    Plugin::OutputList outputs = this->adapter->getOutputDescriptors();
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
        throw runtime_error("Failed to identify chords output");
    }
    // features at end of processing (actually Chordino does all its work here)
    Plugin::FeatureSet fs = this->adapter->getRemainingFeatures();
    Plugin::FeatureList& chordFeatures = fs[chordFeatureNo];
    vector<chord_info_t> result = vector<chord_info_t>((int) chordFeatures.size());
    for (int i = 0; i < (int)chordFeatures.size(); ++i)
    {
        result[i].chord = chordFeatures[i].label;
        result[i].time = chordFeatures[i].timestamp.msec() / 1000.f;
    }
    return result;
}

void ChordExtract::reset()
{
    this->adapter->reset();
}
