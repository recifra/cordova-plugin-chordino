//
//  Chordino.mm
//  Chordino
//
//  Created by Francimar Alves on 28/10/23.
//

#import <Foundation/Foundation.h>

#import "Chordino.h"
#include "chordextract.h"

@interface ChordItem ()
@end

@implementation ChordItem
- (instancetype)initWithChord:(NSString *)chord time:(float)time {
    if (self = [super init]) {
        self.chord = chord;
        self.time = time;
    }
    return self;
}
@end

@interface ChordinoWrapper ()
@property ChordExtract* extractor;
@end

@implementation ChordinoWrapper

- (instancetype)initWithSamplerate:(float)samplerate {
    if (self = [super init]) {
        self.extractor = new ChordExtract(samplerate);
    }
    return self;
}

-(void)prepare:(size_t)blocksize {
    self.extractor->initialize(blocksize);
}

- (void)process:(float *)bufferArray milliseconds:(long)milliseconds {
    self.extractor->process(bufferArray, milliseconds);
}

- (NSMutableArray *)getResult {
    std::vector<chord_info_t> list;
    self.extractor->getResult(list);
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for (int i = 0; i < (int)list.size(); ++i)
    {
        NSString* chordString = [NSString stringWithUTF8String:list[i].chord.c_str()];
        [result addObject:[[ChordItem alloc] initWithChord:chordString time:list[i].time]];
    }
    return result;
}

-(void)reset {
    self.extractor->reset();
}

- (void)dealloc {
    delete self.extractor;
}

@end
