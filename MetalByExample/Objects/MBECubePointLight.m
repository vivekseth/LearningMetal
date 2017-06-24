//
//  MBECubePointLight.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/17/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBECubePointLight.h"
#import "MBECube.h"

@interface MBECubePointLight ()

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;
@property id<MTLBuffer> vertexObjectUniformsBuffer;
@property id<MTLBuffer> fragmentPointLightUniformBuffer;

@end

@implementation MBECubePointLight

@synthesize device;
@synthesize x, y, z;
@synthesize color, strength;
@synthesize K, L, Q;

- (instancetype)initWithDevice:(id<MTLDevice>)device color:(vector_float4)color strength:(float)strength K:(float)K L:(float)L Q:(float)Q
{
	self = [super init];

	self.device = device;
	self.color = color;
	self.strength = strength;
	self.K = K;
	self.L = L;
	self.Q = Q;

	[self makeBuffers];

	return self;
}

- (void)makeBuffers
{
	static const MBEVertexIn vertices[] =
	{
		{ .position = { -1,  1,  1, 1 }, .color = { 0, 1, 1, 1 }, .normal = {0, 0, 0}},
		{ .position = { -1, -1,  1, 1 }, .color = { 0, 0, 1, 1 }, .normal = {0, 0, 0}},
		{ .position = {  1, -1,  1, 1 }, .color = { 1, 0, 1, 1 }, .normal = {0, 0, 0}},
		{ .position = {  1,  1,  1, 1 }, .color = { 1, 1, 1, 1 }, .normal = {0, 0, 0}},
		{ .position = { -1,  1, -1, 1 }, .color = { 0, 1, 0, 1 }, .normal = {0, 0, 0}},
		{ .position = { -1, -1, -1, 1 }, .color = { 0, 0, 0, 1 }, .normal = {0, 0, 0}},
		{ .position = {  1, -1, -1, 1 }, .color = { 1, 0, 0, 1 }, .normal = {0, 0, 0}},
		{ .position = {  1,  1, -1, 1 }, .color = { 1, 1, 0, 1 }, .normal = {0, 0, 0}}
	};

	static const MBEIndex indices[] =
	{
		3, 2, 6, 6, 7, 3,
		4, 5, 1, 1, 0, 4,
		4, 0, 3, 3, 7, 4,
		1, 5, 6, 6, 2, 1,
		0, 1, 2, 2, 3, 0,
		7, 6, 5, 5, 4, 7
	};

	MBEFragmentPointLight pointLight =
	{
		.position = {self.x, self.y, self.z, 1},
		.color = self.color,
		.strength = self.strength,

		.K = self.K,
		.L = self.L,
		.Q = self.Q,
	};

	self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];

	self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceOptionCPUCacheModeDefault];
	[self.indexBuffer setLabel:@"Indices"];

	self.vertexObjectUniformsBuffer = [self.device newBufferWithLength:sizeof(MBEVertexObjectUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexObjectUniformsBuffer setLabel:@"vertexObjectUniformsBuffer"];

	self.fragmentPointLightUniformBuffer = [self.device newBufferWithBytes:&pointLight length:sizeof(pointLight) options:MTLResourceOptionCPUCacheModeDefault];
	[self.fragmentPointLightUniformBuffer setLabel:@"fragmentPointLightUniformBuffer"];
}

#pragma mark - <MBEPointLightSource>

- (void) encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder {
	[renderCommandEncoder setVertexBuffer:self.vertexObjectUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
	[renderCommandEncoder setFragmentBuffer:self.fragmentPointLightUniformBuffer offset:0 atIndex:1];
	[renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
									 indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
									  indexType:MBEIndexType
									indexBuffer:self.indexBuffer
							  indexBufferOffset:0];
}

- (void) updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView
{
//	float rotationX = duration * (M_PI / 2);
//	float rotationY = duration * (M_PI / 3);

//	vector_float3 xAxis = { 1, 0, 0 };
//	vector_float3 yAxis = { 0, 0, 1 };

//	matrix_float4x4 xRot = matrix_float4x4_rotation(xAxis, rotationX);
//	matrix_float4x4 yRot = matrix_float4x4_rotation(yAxis, rotationY);
//	matrix_float4x4 rotationMatrix = matrix_multiply(xRot, yRot);

	MBEVertexObjectUniforms uniforms;
	matrix_float4x4 translateMatrix = matrix_float4x4_translation((vector_float3){self.x, self.y, self.z});
	matrix_float4x4 scaleMatrix = matrix_float4x4_uniform_scale(0.2);
	uniforms.modelToWorld = matrix_multiply(translateMatrix, scaleMatrix);
	vector_float4 newPosition = (vector_float4){self.x, self.y, self.z, 1.0};
	self.x = newPosition.x;
	self.y = newPosition.y;
	self.z = newPosition.z;



	matrix_float4x4 modelToView = matrix_multiply(worldToView, uniforms.modelToWorld);
	matrix_float3x3 initialNormalMatrix = {
		.columns[0] = modelToView.columns[0].xyz,
		.columns[1] = modelToView.columns[1].xyz,
		.columns[2] = modelToView.columns[2].xyz,
	};
	uniforms.normalMatrix = simd_transpose(simd_inverse(initialNormalMatrix));

	memcpy([self.vertexObjectUniformsBuffer contents], &uniforms, sizeof(uniforms));

	MBEFragmentPointLight pointLight =
	{
		.position = {self.x, self.y, self.z, 1},
		.color = self.color,
		.strength = self.strength,

		.K = self.K,
		.L = self.L,
		.Q = self.Q,
	};
	memcpy([self.fragmentPointLightUniformBuffer contents], &pointLight, sizeof(pointLight));
}

@end
