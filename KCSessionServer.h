//
//  KCSessionServer.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import <Foundation/Foundation.h>
#import "KCSession.h"

@class KCSessionServer;

@protocol KCSessionServerDelegate <NSObject>
- (void)server:(KCSessionServer *)server session:(KCSession *)session receivedMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;
@end

@interface KCSessionServer : NSObject <NSNetServiceDelegate, KCSessionDelegate>

@property (nonatomic, assign) id<KCSessionServerDelegate> delegate;

- (id)initWithDelegate:(id<KCSessionServerDelegate>)delegate;

- (void)broadcastServerMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object;
    
@end
