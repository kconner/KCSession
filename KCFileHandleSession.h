//
//  KCFileHandleSession.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCSession.h"

// A KCSession that creates its streams from a file handle, such as for a network socket.

// You can use this object directly if you have a NSFileHandle. To see how to do that, examine KCSessionServer.m.

@interface KCFileHandleSession : KCSession

- (id)initWithFileHandle:(NSFileHandle *)fileHandle delegate:(id<KCSessionDelegate>)delegate;

@end
