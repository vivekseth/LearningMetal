//
//  MBEObject.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/10/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

@import simd;

#import <Metal/Metal.h>
#import "MBEMathUtilities.h"

typedef uint16_t MBEIndex;
static const MTLIndexType MBEIndexType = MTLIndexTypeUInt16;

@protocol MBEObject

@required;

@property (nonatomic) id<MTLDevice> device;

@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView viewToProjection:(matrix_float4x4)viewToProjection cameraPosition:(vector_float4)cameraPosition;

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder;

@optional

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView viewToProjection:(matrix_float4x4)viewToProjection cameraPosition:(vector_float4)cameraPosition lightSourcePosition:(vector_float4)lightSourcePosition;

@end