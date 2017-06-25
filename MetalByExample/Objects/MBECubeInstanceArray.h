//
//  MBECubeInstanceArray.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/25/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "MBESphere.h"
#import "MBEObject.h"
#import "MBEShaderStructs.h"

@interface MBECubeInstanceArray : NSObject <MBEObject, MBERenderable>

@property (nonatomic) NSUInteger instanceCount;

- (instancetype)initWithDevice:(id<MTLDevice>)device instanceCount:(NSUInteger)instanceCount;

- (id<MBEObject>)objectAtIndexedSubscript:(NSUInteger)idx;

@end
