//
//  MBEPlane.m
//  MetalByExample
//
//  Created by Vivek Seth on 7/4/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBEPlane.h"

@interface MBEPlane ()

@property id<MTLBuffer> vertexBuffer;

@property id<MTLBuffer> vertexObjectUniformsBuffer;
@property id<MTLBuffer> fragmentMaterialUniformsBuffer;

@end

@implementation MBEPlane

@synthesize device;
@synthesize x, y, z, scale;

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
	self = [super init];

	self.device = device;
	self.scale = 1.0;
	self.width = 1.0;
	self.height = 1.0;
	self.rotationMatrix = matrix_float4x4_uniform_scale(1.0);

	[self makeBuffers];

	return self;
}

- (void)makeBuffers {
	static const MBEVertexIn vertices[] =
	{
		{.position = { -0.5f,  0,  -0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { 0.5f,  0,  0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { 0.5f,  0,  -0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { 0.5f,  0,  0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { -0.5f,  0,  -0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { -0.5f,  0,  0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
	};

	self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];

	self.vertexObjectUniformsBuffer = [self.device newBufferWithLength:sizeof(MBEVertexObjectUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexObjectUniformsBuffer setLabel:@"vertexObjectUniformsBuffer"];

	// TODO(vivek): allow users to modify this.
	MBEFragmentMaterialUniforms fragmentMaterialUniforms;
	fragmentMaterialUniforms.objectColor = (vector_float4){1, 1, 1, 1};
	fragmentMaterialUniforms.ambientStrength = 0.3;
	fragmentMaterialUniforms.diffuseStrength = 0.7;
	fragmentMaterialUniforms.specularStrength = 0.4;
	fragmentMaterialUniforms.specularFactor = 32;

	self.fragmentMaterialUniformsBuffer = [self.device newBufferWithBytes:&fragmentMaterialUniforms length:sizeof(fragmentMaterialUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.fragmentMaterialUniformsBuffer setLabel:@"fragmentMaterialUniformsBuffer"];
}

#pragma mark <MBEObject>

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder
{
	[renderCommandEncoder setVertexBuffer:self.vertexObjectUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
	[renderCommandEncoder setFragmentBuffer:self.fragmentMaterialUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView {
	vector_float3 position = {self.x, self.y, self.z};
	const matrix_float4x4 positionMatrix = matrix_float4x4_translation(position);
	const matrix_float4x4 scaleMatrix = matrix_float4x4_scale((vector_float3){self.width, 1, self.height});
	const matrix_float4x4 modelToWorld = matrix_multiply(positionMatrix, matrix_multiply(self.rotationMatrix, scaleMatrix));

	MBEVertexObjectUniforms uniforms;
	uniforms.modelToWorld = modelToWorld;

	matrix_float4x4 modelToView = modelToWorld;

	matrix_float3x3 initialNormalMatrix = {
		.columns[0] = modelToView.columns[0].xyz,
		.columns[1] = modelToView.columns[1].xyz,
		.columns[2] = modelToView.columns[2].xyz,
	};
	uniforms.normalMatrix = simd_transpose(simd_inverse(initialNormalMatrix));

	memcpy([self.vertexObjectUniformsBuffer contents], &uniforms, sizeof(uniforms));
}

@end
