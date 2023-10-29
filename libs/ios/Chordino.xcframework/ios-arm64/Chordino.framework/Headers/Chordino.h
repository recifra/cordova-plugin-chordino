//
//  Chordino.h
//  Chordino
//
//  Created by Francimar Alves on 28/10/23.
//

#import <Foundation/Foundation.h>

//! Project version number for Chordino.
FOUNDATION_EXPORT double ChordinoVersionNumber;

//! Project version string for Chordino.
FOUNDATION_EXPORT const unsigned char ChordinoVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Chordino/PublicHeader.h>

@interface ChordItem : NSObject
@property (nonatomic, strong) NSString *chord;
@property float time;
- (instancetype)initWithChord:(NSString *)chord time:(float)time;
@end

@interface ChordinoWrapper : NSObject
- (instancetype)initWithSamplerate:(float)samplerate;
- (void)prepare:(size_t)blocksize;
- (void)process:(float*)bufferArray milliseconds:(long)milliseconds;
- (NSMutableArray*)getResult;
- (void)reset;
- (void)dealloc;
@end
