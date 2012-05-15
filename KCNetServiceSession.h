//
//  KCNetServiceSession.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCSession.h"

// A KCSession that creates its streams from a NSNetService.

// To use this object, first you need a NSNetService.
// You can discover a NSNetService by using a NSNetServiceBrowser to search for the same service type as you used in your KCSessionServer.

// Upon initialization, the KCNetServiceSession will try to resolve the remote service and open streams to it. It will likely return before this completes.

// The delegate will ideally receive -sessionDidConnect: or -sessionDidNotConnect.
// If you receive -sessionDidConnect:, you can send and receive messages freely, until you receive -sessionDidDisconnect:.
// If you receive -sessionDidNotConnect: or -sessionDidDisconnect:, discard this object.
// To reconnect, you should create a new object.

@interface KCNetServiceSession : KCSession <NSNetServiceDelegate>

- (id)initWithNetService:(NSNetService *)service delegate:(id<KCSessionDelegate>)delegate;

@end
