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

@interface KCSessionServer()
#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
@property (nonatomic, strong) NSSocketPort *socketPort;
#else
@property (nonatomic, assign) CFSocketRef cfsocket;
#endif
@property (nonatomic, strong) NSFileHandle *socketHandle;
@property (nonatomic, strong) NSNetService *netService;
@property (nonatomic, strong) NSMutableArray *clientSessions;
@end

@implementation KCSessionServer

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
@synthesize socketPort = _socketPort;
#else
@synthesize cfsocket = _cfsocket;
#endif
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
        NSLog(@"%s: NSFileHandle Error: %@", __func__, errorNo);
        return;
    }
    
    [self.socketHandle acceptConnectionInBackgroundAndNotify]; // Keep listening
    
    if (clientSocketHandle) {
        __unused KCFileHandleSession *session = [[KCFileHandleSession alloc] initWithFileHandle:clientSocketHandle delegate:self];
    }
}

- (BOOL)beginPublishingServiceWithServiceType:(NSString *)serviceType {
    BOOL success = YES;
    int port;
    int socketDescriptor;
    #if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
    // Adapted from https://developer.apple.com/library/mac/#documentation/Networking/Conceptual/NSNetServiceProgGuide/Articles/PublishingServices.html#//apple_ref/doc/uid/20001076-SW1
    self.socketPort = [[NSSocketPort alloc] initWithTCPPort:0];
    if (self.socketPort) {
        socketDescriptor = [self.socketPort socket];
        
        struct sockaddr *addr = (struct sockaddr *)[[self.socketPort address] bytes];
        if (addr->sa_family == AF_INET) {
            port = ntohs(((struct sockaddr_in *)addr)->sin_port);
        }
        else if (addr->sa_family == AF_INET6) {
            port = ntohs(((struct sockaddr_in6 *)addr)->sin6_port);
        }
        else {
            self.socketPort = nil;
            NSLog(@"%s: The family is neither IPv4 nor IPv6. Can't handle.", __func__);
            success = NO;
        }
    }
    else {
        NSLog(@"%s: NSSocketPort failed to initialize.", __func__);
        success = NO;
    }
    #else
    // Adapted from http://cocoawithlove.com/2009/07/simple-extensible-http-server-in-cocoa.html
    _cfsocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, NULL, NULL);
    if (_cfsocket == NULL) {
        NSLog(@"%s: Unable to create socket.", __func__);
        success = NO;
    }
    
    if (success) {
        int reuse = true;
        socketDescriptor = CFSocketGetNative(_cfsocket);
        if (setsockopt(socketDescriptor, SOL_SOCKET, SO_REUSEADDR, (void *)&reuse, sizeof(int)) != 0) {
            NSLog(@"%s: Unable to set socket options.", __func__);
            success = NO;
        }
    }
    
    if (success) {
        // Ask the socket to bind to a port that the system may select
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_ANY);
        addr.sin_port = 0; // Select the port automatically.
        
        CFDataRef addressData = CFDataCreate(NULL, (const UInt8 *)&addr, sizeof(addr));
        if (CFSocketSetAddress(_cfsocket, addressData) != kCFSocketSuccess) {
            NSLog(@"%s: Unable to bind socket to address.", __func__);
            success = NO;
        } 
        CFRelease(addressData);
        
        // Discover the port that was chosen
        if (success) {
            addressData = CFSocketCopyAddress(_cfsocket);
            struct sockaddr_in *addrWithPort = (struct sockaddr_in *) CFDataGetBytePtr(addressData);
            port = ntohs(addrWithPort->sin_port);
            CFRelease(addressData);
        }
    }
    #endif

    if (success) {
        self.netService = [[NSNetService alloc] initWithDomain:@"" type:serviceType name:@"" port:port];
        if (self.netService) {
            self.socketHandle = [[NSFileHandle alloc] initWithFileDescriptor:socketDescriptor closeOnDealloc:YES];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionAccepted:) name:NSFileHandleConnectionAcceptedNotification object:self.socketHandle];
            [self.socketHandle acceptConnectionInBackgroundAndNotify];
            
            self.netService.delegate = self;
            [self.netService publish];
        }
        else {
            NSLog(@"%s: NSNetService failed to initialize and publish.", __func__);
            success = NO;
        }
    }
    else {
        NSLog(@"%s: NSSocketPort failed to initialize.", __func__);
        success = NO;
    }
    
    if (!success) {
        #if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
        self.socketPort = nil;
        #else
        CFRelease(_cfsocket);
        #endif
    }
    
    return success;
}

#pragma mark - Init/dealloc

- (id)initWithServiceType:(NSString *)serviceType delegate:(id<KCSessionServerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.clientSessions = [NSMutableArray array];
        
        if (![self beginPublishingServiceWithServiceType:serviceType]) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.netService.delegate = nil;
    [self.netService stop];
     
    #if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
    // No-op
    #else
    if (_cfsocket) {
		CFSocketInvalidate(_cfsocket);
		CFRelease(_cfsocket);
		_cfsocket = nil;
	}
    #endif
}

#pragma mark - Public interface

- (void)broadcastMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object {
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

- (void)sessionDidConnect:(KCSession *)session {
    NSLog(@"%s: Client connected.", __func__);
    [self.clientSessions addObject:session];
    if ([self.delegate respondsToSelector:@selector(server:clientDidConnectWithSession:)]) {
        [self.delegate server:self clientDidConnectWithSession:session];
    }
}

- (void)sessionDidNotConnect:(KCSession *)session {
    NSLog(@"%s: Client failed to connect.", __func__);
}

- (void)sessionDidDisconnect:(KCSession *)session {
    NSLog(@"%s: Client disconnected.", __func__);
    [self.clientSessions removeObject:session];
    if ([self.delegate respondsToSelector:@selector(server:clientDidDisconnectWithSession:)]) {
        [self.delegate server:self clientDidDisconnectWithSession:session];
    }
}

- (void)session:(KCSession *)session didReceiveMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object {
    [self.delegate server:self session:session didReceiveMessageWithOpcode:opcode object:object];
}

@end
