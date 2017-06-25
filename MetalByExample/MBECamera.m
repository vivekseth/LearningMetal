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
	_target = (vector_float3){0.0f, 0.0f, 0.0f};
	_up = (vector_float3){0.0f, 1.0f,  0.0f};
	_pitch = 0;
	_yaw = M_PI_2;

	return self;
}

- (vector_float3)front
{
	return simd_normalize(self.target - self.position);
}

- (void)setFront:(vector_float3)front
{
	self.target = self.position + simd_normalize(front);
}

- (void)setYaw:(float)yaw
{
	_yaw = yaw;

	[self _updateFrontWithAngles];
}

- (void)setPitch:(float)pitch
{
	_pitch = pitch;

	[self _updateFrontWithAngles];
}

- (void)_updateFrontWithAngles
{
	vector_float3 front;
	front.x = cos(self.yaw) * cos(self.pitch);
	front.y = sin(self.pitch);
	front.z = sin(self.yaw) * cos(self.pitch);
	self.front = simd_normalize(front);
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
