//
//  MBECube.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <simd/simd.h>
#import "MBECube.h"
#import "MBEMathUtilities.h"
#import "MBEShaderStructs.h"

@interface MBECube ()

@property (readonly) id <MTLRenderPipelineState> renderPipelineState;

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;
@property id<MTLBuffer> objectUniformsBuffer;

@end

@implementation MBECube

@synthesize device;

@synthesize x, y, z;

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
	self = [super init];

	self.device = device;

	[self makePipeline];
	[self makeBuffers];

	return self;
}

- (void)makeBuffers {
	static const MBEVertexIn vertices[] =
	{
		{ .position = { -1,  1,  1, 1 }, .color = { 0, 1, 1, 1 }, .normal = {0, 0, 0} },
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

	self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];

	self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceOptionCPUCacheModeDefault];
	[self.indexBuffer setLabel:@"Indices"];

	self.objectUniformsBuffer = [self.device newBufferWithLength:sizeof(MBEVertexObjectUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.objectUniformsBuffer setLabel:@"objectUniformsBuffer"];
}

- (void)makePipeline
{
	id<MTLLibrary> library = [self.device newDefaultLibrary];

	MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_project"];
	pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_flatcolor"];
	pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

	NSError *error = nil;
	_renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
	if (!self.renderPipelineState)
	{
		NSLog(@"Error occurred when creating render pipeline state: %@", error);
	}
}

#pragma mark <MBEObject>

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder
{
	// TODO(vivek): fix this!
	assert(NO);
//	[renderCommandEncoder setRenderPipelineState:self.renderPipelineState];
//
//	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
//	[renderCommandEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:1];
//
//	[renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
//									 indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
//									  indexType:MBEIndexType
//									indexBuffer:self.indexBuffer
//							  indexBufferOffset:0];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView {
	// TODO(vivek): fix this!
	assert(NO);
//	MBEVertexObjectUniforms uniforms;
//	uniforms.modelToWorld = matrix_float4x4_translation((vector_float3){self.x, self.y, self.z});
//
//	matrix_float4x4 modelToView = matrix_multiply(worldToView, uniforms.modelToWorld);
//	matrix_float3x3 initialNormalMatrix = {
//		.columns[0] = modelToView.columns[0].xyz,
//		.columns[1] = modelToView.columns[1].xyz,
//		.columns[2] = modelToView.columns[2].xyz,
//	};
//	uniforms.normalMatrix = simd_transpose(simd_inverse(initialNormalMatrix));
//
//	memcpy([self.objectUniformsBuffer contents], &uniforms, sizeof(uniforms));
}

@end
