//
//  MBECamera.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/24/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

@interface MBECamera : NSObject

+ (matrix_float4x4)worldToViewMatrixWithPosition:(vector_float3)position target:(vector_float3)target up:(vector_float3)up;

@end
