//
//  _MBEObjectInstance.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/25/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "_MBEObjectInstance.h"

@implementation _MBEObjectInstance

@synthesize x, y, z, scale;

- (instancetype)initWithVertexObjectUniformsBufferPointer:(void *)vertexObjectUniformsBufferPointer
{
	self = [super init];
	_vertexObjectUniformsBufferPointer = vertexObjectUniformsBufferPointer;
	return self;
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView
{
	const matrix_float4x4 positionMatrix = matrix_float4x4_translation((vector_float3){self.x, self.y, self.z});
	const matrix_float4x4 scaleMatrix = matrix_float4x4_uniform_scale(self.scale);
	const matrix_float4x4 modelToWorld = matrix_multiply(positionMatrix, scaleMatrix);

	MBEVertexObjectUniforms uniforms;
	uniforms.modelToWorld = modelToWorld;

	matrix_float4x4 modelToView = modelToWorld;

	matrix_float3x3 initialNormalMatrix = {
		.columns[0] = modelToView.columns[0].xyz,
		.columns[1] = modelToView.columns[1].xyz,
		.columns[2] = modelToView.columns[2].xyz,
	};
	uniforms.normalMatrix = simd_transpose(simd_inverse(initialNormalMatrix));

	memcpy(self.vertexObjectUniformsBufferPointer, &uniforms, sizeof(uniforms));
}

@end
