//
//  FileHandleInputStream.m
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCFileHandleInputStream.h"

@interface KCFileHandleInputStream ()
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSMutableArray *dataParts;
@property (nonatomic, strong) NSData *currentDataPart;
@property (nonatomic, assign) NSUInteger currentDataPartBytesRead;
@end

@implementation KCFileHandleInputStream

@synthesize fileHandle = _fileHandle;
@synthesize dataParts = _dataParts;
@synthesize currentDataPart = _currentDataPart;
@synthesize currentDataPartBytesRead = _currentDataPartBytesRead;

@synthesize delegate = _delegate;

#pragma mark - Helpers

- (void)addDataPart:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    NSNumber *errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if (errorNo) {
        [self.delegate stream:self handleEvent:NSStreamEventErrorOccurred];
        return;
    }
    
    NSData *data = [userInfo objectForKey:NSFileHandleNotificationDataItem];
    NSUInteger remainingBytes = data.length;
    if (remainingBytes == 0) {
        [self.delegate stream:self handleEvent:NSStreamEventEndEncountered];
        return;
    }
    
    [self.dataParts addObject:data];
    
    if (self.dataParts.count == 1) {
        [self.delegate stream:self handleEvent:NSStreamEventHasBytesAvailable];
    }
        
    [self.fileHandle readInBackgroundAndNotify];
}

#pragma mark - Init/dealloc

- (id)initWithFileHandle:(NSFileHandle *)fileHandle {
    if (self = [super init]) {
        self.fileHandle = fileHandle;
        self.dataParts = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDataPart:) name:NSFileHandleReadCompletionNotification object:fileHandle];
        [fileHandle readInBackgroundAndNotify];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSInputStream

- (BOOL)hasBytesAvailable {
    return self.currentDataPart != nil || 0 < self.dataParts.count;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    if (self.dataParts.count == 0) {
        return 0;
    }
    
    if (self.currentDataPart == nil) {
        self.currentDataPart = [self.dataParts objectAtIndex:0];
        self.currentDataPartBytesRead = 0;
        [self.dataParts removeObjectAtIndex:0];
    }
    
    uint8_t *dataPartBuffer = (uint8_t *) self.currentDataPart.bytes + self.currentDataPartBytesRead;
    NSUInteger dataPartBytesRemaining = self.currentDataPart.length - self.currentDataPartBytesRead;
    
    if (dataPartBytesRemaining <= len) {
        memcpy(buffer, dataPartBuffer, dataPartBytesRemaining);
        self.currentDataPart = nil;
        return dataPartBytesRemaining;
    }
    else {
        memcpy(buffer, dataPartBuffer, len);
        self.currentDataPartBytesRead += len;
        return len;
    }
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
