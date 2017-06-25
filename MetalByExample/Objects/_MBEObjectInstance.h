//
//  _MBEObjectInstance.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/25/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBEObject.h"

@interface _MBEObjectInstance : NSObject <MBEObject>

@property (nonatomic) void *vertexObjectUniformsBufferPointer;

- (instancetype)initWithVertexObjectUniformsBufferPointer:(void *)vertexObjectUniformsBufferPointer;

@end
