//
//  KCFileHandleOutputStream.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import <Foundation/Foundation.h>

// An output stream that writes to a file handle.

// Currently, writes are synchronous. In the future I want to do a synchronous copy of the data,
// and schedule small writes asynchronously on the main run loop.

@interface KCFileHandleOutputStream : NSOutputStream

@property (nonatomic, assign) id<NSStreamDelegate> delegate;

- (id)initWithFileHandle:(NSFileHandle *)fileHandle;

@end
