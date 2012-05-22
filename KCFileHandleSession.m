//
//  KCFileHandleSession.m
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCFileHandleSession.h"
#import "KCFileHandleInputStream.h"
#import "KCFileHandleOutputStream.h"

@implementation KCFileHandleSession

- (id)initWithFileHandle:(NSFileHandle *)fileHandle delegate:(id<KCSessionDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        [self establishConnectionWithInputStream:[[KCFileHandleInputStream alloc] initWithFileHandle:fileHandle]
                                    outputStream:[[KCFileHandleOutputStream alloc] initWithFileHandle:fileHandle]];
    }
    return self;
}

@end
