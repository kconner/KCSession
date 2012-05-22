//
//  KCFileHandleSession.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCSession.h"

@interface KCFileHandleSession : KCSession

- (id)initWithFileHandle:(NSFileHandle *)fileHandle delegate:(id<KCSessionDelegate>)delegate;

@end
