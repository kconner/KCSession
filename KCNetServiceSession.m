//
//  KCNetServiceSession.m
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCNetServiceSession.h"
#import <arpa/inet.h>

@interface KCNetServiceSession ()
@property (nonatomic, strong) NSNetService *netService;
@end

@implementation KCNetServiceSession

@synthesize netService = _netService;

#pragma mark - KCSession

- (void)disconnect {
    [super disconnect];
    
    self.netService.delegate = nil;
    self.netService = nil;
}

#pragma mark - Init/dealloc

- (id)initWithNetService:(NSNetService *)service delegate:(id<KCSessionDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        // The browser could initialize sessions with the same service twice, but you don't want to ask the same NSNetService to resolve twice.
        // So just make a copy of the found service and use that.
        NSNetService *serviceCopy = [[NSNetService alloc] initWithDomain:service.domain type:service.type name:service.name];
        self.netService = serviceCopy;
        
        [self.netService setDelegate:self];
        [self.netService resolveWithTimeout:2];
    }
    return self;
}

- (void)dealloc {
    self.netService.delegate = nil;
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSInputStream *inputStream = nil;
    NSOutputStream *outputStream = nil;
    [self.netService getInputStream:&inputStream outputStream:&outputStream];
    [self connectWithInputStream:inputStream outputStream:outputStream];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    self.netService.delegate = nil;
    self.netService = nil;
    
    [self.delegate sessionDidNotConnect:self];
}

@end
