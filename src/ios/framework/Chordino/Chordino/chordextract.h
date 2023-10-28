//
//  chordextract.h
//  Chordino
//
//  Created by Francimar Alves on 28/10/23.
//

#ifndef chordextract_h
#define chordextract_h

#include <string>
#include <vector>
#include <vamp-hostsdk/PluginBufferingAdapter.h>

typedef struct chord_info_t {
    std::string chord;
    float time;
} chord_info_t;

class ChordExtract {
private:
    Vamp::HostExt::PluginBufferingAdapter* adapter;
public:
    ChordExtract(float samplerate);
    ~ChordExtract();
    void initialize(size_t blocksize);
    void process(float* bufferArray, long milliseconds);
    std::vector<chord_info_t> getResult();
    void reset();
};

#endif /* chordextract_h */
