//
//  MBECamera.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/24/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBECamera.h"
#import "MBEMathUtilities.h"

@implementation MBECamera

- (instancetype)init{
	self = [super init];

	_position = (vector_float3){0.0f, 0.0f,  5.0f};
	_target = (vector_float3){0.0f, 0.0f,  0.0f};
	_up = (vector_float3){0.0f, 1.0f,  0.0f};

	return self;
}

- (matrix_float4x4)worldToViewMatrix
{
	return [self.class worldToViewMatrixWithPosition:self.position target:self.target up:self.up];
}

+ (matrix_float4x4)worldToViewMatrixWithPosition:(vector_float3)position target:(vector_float3)target up:(vector_float3)up
{
	vector_float3 normCameraDirection = simd_normalize(position - target);
	vector_float3 normCameraRight = simd_normalize(simd_cross(up, normCameraDirection));
	vector_float3 normCameraUp = simd_cross(normCameraDirection, normCameraRight);
	matrix_float4x4 cameraLocalCoordinateSpaceMatrix = {
		.columns[0] = {normCameraRight.x, normCameraUp.x, normCameraDirection.x, 0},
		.columns[1] = {normCameraRight.y, normCameraUp.y, normCameraDirection.y, 0},
		.columns[2] = {normCameraRight.z, normCameraUp.z, normCameraDirection.z, 0},
		.columns[3] = {                0,              0,                     0, 1},
	};
	matrix_float4x4 cameraTranslationMatrix = matrix_float4x4_translation(-1.0 * position);
	return matrix_multiply(cameraLocalCoordinateSpaceMatrix, cameraTranslationMatrix);
}

@end
