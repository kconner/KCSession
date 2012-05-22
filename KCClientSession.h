//
//  KCClientSession.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KCSession.h"

// A KCSession that creates its streams from a NSNetService.

// To use this class, first locate an NSNetService using an NSNetServiceBrowser, then initialize this object.
// The KCClientSession will try to open streams to the remote service.
// In response, the delegate will either receive -sessionDidNotEstablishConnection:,
// or -sessionDidEstablishConnection:, in which case you can send and will receive messages until you receive -sessionDidDisconnect:.
// If you receive -sessionDidNotEstablishConnection: or -sessionDidDisconnect:, discard this object.
// To reconnect, create a new object.

@interface KCClientSession : KCSession <NSNetServiceDelegate>

- (id)initWithNetService:(NSNetService *)service delegate:(id<KCSessionDelegate>)delegate;

@end
