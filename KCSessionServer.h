//
//  KCSessionServer.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import <Foundation/Foundation.h>
#import "KCSession.h"

// A server for KCSession connections.

// During initialization, KCSessionServer uses Bonjour to get a port and begins listening on that socket.
// Clients can find the service using NSNetServiceBrowser and then connect with a KCNetServiceSession.

// Create the server with a NSNetService type, such as "_myservice._tcp", and a delegate.
// During initialization the service will attept to begin publishing. If it fails, you will get nil.
// Otherwise, the service is published and listening.

// After a client connects, to send a message, use [session sendMessageWithOpcode:object:].
// To send a message to every connected client, use -broadcastMessageWithOpcode:object:.

// Your delegate will receive -server:session:didReceiveMessageWithOpcode:object: when the server gets a message.
// If your service is request-based, you can simply respond immediately using the session object.
// If you want to push data to the client without a request, you'll want to implement the connection and disconnection messages
// and retain any connected sessions.

@class KCSessionServer;

@protocol KCSessionServerDelegate <NSObject>
- (void)server:(KCSessionServer *)server session:(KCSession *)session didReceiveMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;

@optional
- (void)server:(KCSessionServer *)server clientDidConnectWithSession:(KCSession *)session;
- (void)server:(KCSessionServer *)server clientDidDisconnectWithSession:(KCSession *)session;
@end

@interface KCSessionServer : NSObject <NSNetServiceDelegate, KCSessionDelegate>

@property (nonatomic, assign) id<KCSessionServerDelegate> delegate;

- (id)initWithServiceType:(NSString *)serviceType delegate:(id<KCSessionServerDelegate>)delegate;

- (void)broadcastMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;
    
@end
