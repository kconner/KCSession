//
//  KCFileHandleOutputStream.m
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCFileHandleOutputStream.h"

// This class is adapted from http://stackoverflow.com/a/7136709/10906

@interface KCFileHandleOutputStream ()
@property (nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation KCFileHandleOutputStream

@synthesize delegate;

@synthesize fileHandle = _fileHandle;

#pragma mark - Init/dealloc

- (id)initWithFileHandle:(NSFileHandle *)fileHandle {
    if (self = [super init]) {
        self.fileHandle = fileHandle;
    }
    return self;
}

#pragma mark - NSOutputStream

- (BOOL)hasSpaceAvailable {
    return YES;
}

- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)length {
    // TODO Don't write all data at once. Instead, schedule asynchronous main thread writes using parts of the data.
    [self.fileHandle writeData:[NSData dataWithBytesNoCopy:(void *)buffer length:length freeWhenDone:NO]];
    return length;
}

- (void)open {
    [self.delegate stream:self handleEvent:NSStreamEventOpenCompleted];
}

- (void)close {
    [self.delegate stream:self handleEvent:NSStreamEventEndEncountered];
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // No-op.
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // No-op.
}

@end
