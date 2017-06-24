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

/*
 glm::vec3 cameraPos   = glm::vec3(0.0f, 0.0f,  3.0f);
 glm::vec3 cameraFront = glm::vec3(0.0f, 0.0f, -1.0f);
 glm::vec3 cameraUp    = glm::vec3(0.0f, 1.0f,  0.0f);
 */

@property (nonatomic) vector_float3 position;
@property (nonatomic) vector_float3 up;
@property (nonatomic) vector_float3 target;

- (matrix_float4x4)worldToViewMatrix;

+ (matrix_float4x4)worldToViewMatrixWithPosition:(vector_float3)position target:(vector_float3)target up:(vector_float3)up;

@end
