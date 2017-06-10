//
//  MBECube.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MBECube : NSObject

@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration viewProjectionMatrix:(matrix_float4x4)viewProjectionMatrix;

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder;

@end
