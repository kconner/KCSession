//
//  KCSession.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import <Foundation/Foundation.h>

// A KCSession represents a two-way connection from your application to another KCSession in another application.
// KCSessions communicate using messages consisting of an opcode and a serializable object. You must design your protocol on that foundation.

// When you attempt to connect to streams, the delegate will receive -sessionDidConnect: or -sessionDidNotConnect.
// If you receive -sessionDidConnect:, you can send and receive messages freely, until you receive -sessionDidDisconnect:.
// If you receive -sessionDidNotConnect: or -sessionDidDisconnect:, discard this object.
// To reconnect, you should create a new session object.

// A KCSession can use any input stream and output stream to do its work.
// Subclasses work by providing streams to this class from sources like a Bonjour NSNetService or a socket's NSFileHandle.
// If you use this object directly, you should call connectWithInputStream:outputStream and then handle the connection messages.
// Subclasses typically call that method while initializing, so you don't have to.

// Messages consist of an opcode and an object.
// Opcodes can be any integer, so you probably want to enumerate them.
// Objects must be serializable by NSKeyedArchiver and NSKeyedUnarchiver. Objects may be nil.

typedef uint32_t KCSessionOpcode;

@class KCSession;

@protocol KCSessionDelegate <NSObject>
- (void)sessionDidConnect:(KCSession *)session;
- (void)sessionDidNotConnect:(KCSession *)session;
- (void)sessionDidDisconnect:(KCSession *)session;
- (void)session:(KCSession *)session didReceiveMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;
@end

@interface KCSession : NSObject <NSStreamDelegate>

// You are responsible for setting this to nil before releasing the session.
@property (nonatomic, assign) id<KCSessionDelegate> delegate;

// First, create a session object with a KCSessionDelegate. Subclass constructors will call this.
- (id)initWithDelegate:(id<KCSessionDelegate>)delegate;

// Next, establish a connection with input and output streams. Subclasses will do this for you.
// The session will become the streams' delegate and will try to open them for reading.
// After this method is called, the delegate will receive either -sessionDidConnect or -sessionDidNotConnect.
- (void)connectWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

// Disconnect when you are done.
// A session will also disconnect when it is dealloced, but by that time you should have set its delegate to nil.
- (void)disconnect;

// After you receive -sessionDidConnect:, you may call this method to send a message.
// Messages are sent asynchronously on the main thread. You can queue up as many as you like.
// If the session becomes disconnected, not all of these messages may have finished sending.
- (void)sendMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;

@end
