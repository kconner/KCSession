//
//  FileHandleInputStream.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import <Foundation/Foundation.h>

// An input stream that reads from a file handle.

@interface KCFileHandleInputStream : NSInputStream

@property (nonatomic, assign) id<NSStreamDelegate> delegate;

- (id)initWithFileHandle:(NSFileHandle *)fileHandle;

@end
