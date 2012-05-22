//
//  KCSession.m
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import "KCSession.h"

@interface KCSession ()
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableArray *outgoingMessages;
@property (nonatomic, strong) NSData *currentOutgoingMessage;
@property (nonatomic, assign) NSUInteger currentOutgoingMessageBytesSent;
@property (nonatomic, strong) NSMutableData *incomingMessagePart;
@end

@implementation KCSession

@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize outgoingMessages = _outgoingMessages;
@synthesize currentOutgoingMessage = _currentOutgoingMessage;
@synthesize currentOutgoingMessageBytesSent = _currentOutgoingMessageBytesSent;
@synthesize incomingMessagePart = _incomingMessagePart;

@synthesize delegate = _delegate;

#pragma mark - Helpers

- (void)writeOutgoingMessages {
    while (self.outputStream.hasSpaceAvailable) {
        if (self.currentOutgoingMessage == nil) {
            if (self.outgoingMessages.count == 0) {
                break;
            }
            self.currentOutgoingMessage = [self.outgoingMessages objectAtIndex:0];
            self.currentOutgoingMessageBytesSent = 0;
            [self.outgoingMessages removeObjectAtIndex:0];
        }
        
        uint8_t *buffer = (uint8_t *) self.currentOutgoingMessage.bytes + self.currentOutgoingMessageBytesSent;
        NSUInteger length = self.currentOutgoingMessage.length - self.currentOutgoingMessageBytesSent;
        NSUInteger written = [self.outputStream write:buffer maxLength:length];
        if (written < length) {
            self.currentOutgoingMessageBytesSent += written;
            break;
        }
        else {
            self.currentOutgoingMessage = nil;
        }
    }
}

- (void)readIncomingMessages {
    if (!self.inputStream.hasBytesAvailable) {
        return;
    }
    
    // Pull all available data off the stream.
    do {
        NSUInteger bytesRead;
        uint8_t buffer[32768];
        
        // Pull some data off the network.
        bytesRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
        if (bytesRead == -1) {
            NSLog(@"Error reading from input stream.");
            break;
        }
        else if (bytesRead == 0) {
            NSLog(@"No data on stream.");
            break;
        }
        else if (self.incomingMessagePart == nil) {
            self.incomingMessagePart = [NSMutableData dataWithBytes:buffer length:bytesRead];
        }
        else {
            [self.incomingMessagePart appendBytes:buffer length:bytesRead];
        }
    } while (self.inputStream.hasBytesAvailable);
    
    // One or more messages may be encoded in the data. We will pull them out one at a time.
    uint8_t *message = (uint8_t *) self.incomingMessagePart.bytes;
    NSUInteger bytesRemaining = self.incomingMessagePart.length;
    BOOL handledAnyMessages = NO;
    
    while (0 < bytesRemaining) {
        if (bytesRemaining < sizeof(KCSessionOpcode) + sizeof(KCSessionOpcode)) {
            // We have only part of a header. Save it for later and quit.
            break; // TODO test this branch
        }
        
        KCSessionOpcode opcode = 0;
        id object = nil;
        
        // Read the header.
        KCSessionOpcode *header = (KCSessionOpcode *) message;
        opcode = header[0];
        KCSessionOpcode objectLength = header[1];
        uint8_t *objectBytes = (uint8_t *) (&header[2]);
        
        // From the header, determine the total message length
        NSUInteger messageLength = sizeof(KCSessionOpcode) + sizeof(KCSessionOpcode) + objectLength;
        if (bytesRemaining < messageLength) {
            // We have the whole header but not the whole object. Save it for later and quit.
            break;
        }
        
        // Read the object.
        if (0 < objectLength) {
            NSData *objectData = [NSData dataWithBytesNoCopy:objectBytes length:objectLength freeWhenDone:NO];
            object = [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
        }
        
        // We've got the opcode and object in full. Parse and handle it.
        [self.delegate session:self receivedMessageWithOpcode:opcode object:object];
        
        // Point forward to the next message.
        message += messageLength;
        bytesRemaining -= messageLength;
        handledAnyMessages = YES;
    }
    
    if (bytesRemaining == 0) {
        // We read 100% of the bytes. Delete the accumulator.
        self.incomingMessagePart = nil;
    }
    else if (handledAnyMessages) {
        // TODO test this branch
        // We have part of a message, and it doesn't start at the beginning of the buffer.
        // Chop out the completed messages and replace the buffer with one containing just the remainder.
        self.incomingMessagePart = [NSMutableData dataWithBytes:message length:bytesRemaining];
    }
}

#pragma mark - Init/dealloc

- (id)initWithDelegate:(id<KCSessionDelegate>)delegate {
    self = [super init];
    if (self) {
        self.outgoingMessages = [NSMutableArray array];
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    [self disconnect];
}

#pragma mark - Public interface

- (void)establishConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream {
    if (inputStream && outputStream) {
        self.inputStream = inputStream;
        self.outputStream = outputStream;
        self.inputStream.delegate = self;
        self.outputStream.delegate = self;
        [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.inputStream open];
        [self.outputStream open];
        
        [self.delegate sessionDidEstablishConnection:self];
    }
    else {
        [self.delegate sessionDidNotEstablishConnection:self];
    }
}

- (void)disconnect {
    [self.inputStream close];
    [self.outputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.inputStream.delegate = nil;
    self.outputStream.delegate = nil;
    self.inputStream = nil;
    self.outputStream = nil;

    [self.delegate sessionDidDisconnect:self];
}

- (void)sendMessageWithOpcode:(KCSessionOpcode)opcode object:(id)object {
    NSData *objectData = nil;  
    KCSessionOpcode objectLength = 0;
    if (object != nil) {
        objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
        objectLength = objectData.length;
    }
    
    NSUInteger messageLength = sizeof(KCSessionOpcode) + sizeof(KCSessionOpcode) + objectLength;
    NSMutableData *messageData = [NSMutableData dataWithCapacity:messageLength];
    [messageData appendBytes:&opcode length:sizeof(KCSessionOpcode)];
    [messageData appendBytes:&objectLength length:sizeof(KCSessionOpcode)];
    if (objectLength > 0) {
        [messageData appendData:objectData];
    }
    
    [self.outgoingMessages addObject:messageData];
    [self writeOutgoingMessages];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            // No-op.
            break;
        case NSStreamEventHasBytesAvailable:
            assert(aStream == self.inputStream);
            [self readIncomingMessages];
            break;
        case NSStreamEventHasSpaceAvailable:
            assert(aStream == self.outputStream);
            [self writeOutgoingMessages];
            break;
        case NSStreamEventErrorOccurred:
            [self disconnect];
            break;
        case NSStreamEventEndEncountered:
            [self disconnect];
            break;
        default:
            assert(NO);
            break;
    }
}

@end
