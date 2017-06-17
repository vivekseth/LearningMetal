//
//  MBEPointLightSource.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/16/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBEObject.h"
#import "MBEShaderStructs.h"
#import <simd/simd.h>

@protocol MBEPointLightSource <MBEObject>

@property (nonatomic) vector_float4 color;
@property (nonatomic) float strength;
@property (nonatomic) float constant;
@property (nonatomic) float linear;
@property (nonatomic) float quadratic;

@end
