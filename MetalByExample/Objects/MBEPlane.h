//
//  MBEPlane.h
//  MetalByExample
//
//  Created by Vivek Seth on 7/4/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "MBEObject.h"

@interface MBEPlane : NSObject<MBEObject, MBERenderable>

@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) matrix_float4x4 rotationMatrix;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end
