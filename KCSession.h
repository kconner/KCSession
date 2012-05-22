//
//  KCSession.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  Copyright (c) 2012 Kevin Conner. This software is free to use.
//

#import <Foundation/Foundation.h>

// A KCSessionOpcode specifies what kind of message you are sending. You can make an enum for these.
// When calling -sendMessageWithOpcode:object: you can pass one of your enum values for the opcode.
// When handling session:receivedMessageWithOpcode:object:, you can switch on the opcode to find the type of message, including what type the object has.
typedef uint32_t KCSessionOpcode;

@class KCSession;

@protocol KCSessionDelegate <NSObject>
- (void)sessionDidEstablishConnection:(KCSession *)session;
- (void)sessionDidNotEstablishConnection:(KCSession *)session;
- (void)sessionDidDisconnect:(KCSession *)session;
- (void)session:(KCSession *)session receivedMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;
@end

@interface KCSession : NSObject <NSStreamDelegate>

// You are responsible for setting this to nil before releasing the session.
// TODO can I make this a weak reference?
@property (nonatomic, assign) id<KCSessionDelegate> delegate;

// First, create a session object with a KCSessionDelegate. Subclass constructors will call this.
- (id)initWithDelegate:(id<KCSessionDelegate>)delegate;

// Next, establish a connection with input and output streams. Subclasses will do this for you.
// The session will become the streams' delegate and will try to open them for reading.
// After this method is called, the delegate will receive either -sessionDidEstablishConnection or -sessionDidNotEstablishConnection.
- (void)establishConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

// Disconnect when you are done.
// A session will also disconnect when it is dealloced, but by that time you should have set its delegate to nil.
- (void)disconnect;

// After you receive -sessionDidEstablishConnection:, you may call this method to send a message.
// Messages are sent asynchronously on the main thread. You can queue up as many as you like.
// If the session becomes disconnected, not all of these messages may have finished sending.
- (void)sendMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;

@end
