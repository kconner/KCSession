//
//  KCSessionServer.m
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCSessionServer.h"
#import "KCFileHandleSession.h"

#import <netinet/in.h>

@interface KCSessionServer () {
    struct sockaddr *_addr;
    int _port;
}
@property (nonatomic, strong) NSSocketPort *socketPort;
@property (nonatomic, strong) NSFileHandle *socketHandle;
@property (nonatomic, strong) NSNetService *netService;
@property (nonatomic, strong) NSMutableArray *clientSessions;
@end

@implementation KCSessionServer

@synthesize socketPort = _socketPort;
@synthesize socketHandle = _socketHandle;
@synthesize netService = _netService;
@synthesize clientSessions = _clientSessions;

@synthesize delegate = _delegate;

#pragma mark - Helpers

- (void)connectionAccepted:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSFileHandle *clientSocketHandle = [userInfo objectForKey:NSFileHandleNotificationFileHandleItem];
    
    NSNumber *errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if (errorNo) {
        NSLog(@"NSFileHandle Error: %@", errorNo);
        return;
    }
    
    [self.socketHandle acceptConnectionInBackgroundAndNotify]; // Keep listening
    
    if (clientSocketHandle) {
        [[KCFileHandleSession alloc] initWithFileHandle:clientSocketHandle delegate:self];
    }
}

- (BOOL)beginPublishingService {
    // Adapted from https://developer.apple.com/library/mac/#documentation/Networking/Conceptual/NSNetServiceProgGuide/Articles/PublishingServices.html#//apple_ref/doc/uid/20001076-SW1
    self.socketPort = [[NSSocketPort alloc] initWithTCPPort:0];
    if (self.socketPort) {
        _addr = (struct sockaddr *)[[self.socketPort address] bytes];
        if (_addr->sa_family == AF_INET) {
            _port = ntohs(((struct sockaddr_in *)_addr)->sin_port);
        }
        else if (_addr->sa_family == AF_INET6) {
            _port = ntohs(((struct sockaddr_in6 *)_addr)->sin6_port);
        }
        else {
            self.socketPort = nil;
            NSLog(@"The family is neither IPv4 nor IPv6. Can't handle.");
            return NO;
        }
        NSLog(@"Port: %d", _port);
    }
    else {
        NSLog(@"An error occurred initializing the NSSocketPort object.");
        return NO;
    }

    if (self.socketPort) {
        self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_degrees._tcp" name:@"" port:_port];
        if (self.netService) {
            self.socketHandle = [[NSFileHandle alloc] initWithFileDescriptor:[self.socketPort socket] closeOnDealloc:YES];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionAccepted:) name:NSFileHandleConnectionAcceptedNotification object:self.socketHandle];
            [self.socketHandle acceptConnectionInBackgroundAndNotify];
            
            self.netService.delegate = self;
            [self.netService publish];
        }
        else {
            NSLog(@"An error occurred initializing the NSNetService object.");
            self.socketPort = nil;
            return NO;
        }
    }
    else {
        NSLog(@"An error occurred initializing the NSSocketPort object.");
        return NO;
    }
    
    return YES;
}

#pragma mark - Init/dealloc

- (id)initWithDelegate:(id<KCSessionServerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.clientSessions = [NSMutableArray array];
        
        if (![self beginPublishingService]) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.netService.delegate = nil;
    [self.netService stop];
}

#pragma mark - Public interface

- (void)broadcastServerMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object {
    for (KCSession *session in self.clientSessions) {
        [session sendMessageWithOpcode:opcode object:object];
    }
}

#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"%s: *** Did NOT publish: %@: %@", __func__, sender, errorDict);
}

- (void)netServiceWillPublish:(NSNetService *)sender {
    NSLog(@"%s: Will publish: %@", __func__, sender);
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"%s: Did publish: %@", __func__, sender);
}

- (void)netServiceDidStop:(NSNetService *)sender {
    NSLog(@"%s: Stopped: %@", __func__, sender);
}

#pragma mark - KCSessionDelegate

- (void)sessionDidEstablishConnection:(KCSession *)session {
    NSLog(@"Client connected.");
    [self.clientSessions addObject:session];
}

- (void)sessionDidNotEstablishConnection:(KCSession *)session {
    NSLog(@"Client failed to connect!");
}

- (void)sessionDidDisconnect:(KCSession *)session {
    NSLog(@"Client disconnected.");
    [self.clientSessions removeObject:session];
}

- (void)session:(KCSession *)session receivedMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object {
    [self.delegate server:self session:session receivedMessageWithOpcode:opcode object:object];
}

@end
