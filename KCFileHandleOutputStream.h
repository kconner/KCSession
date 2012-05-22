//
//  KCFileHandleOutputStream.h
//  Degrees
//
//  Created by Kevin Conner on 5/22/12.
//  This software is free to use.
//

#import <Foundation/Foundation.h>

@interface KCFileHandleOutputStream : NSOutputStream

@property (nonatomic, assign) id<NSStreamDelegate> delegate;

- (id)initWithFileHandle:(NSFileHandle *)fileHandle;

@end
