//
//  MBECube.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBECube.h"
#import "MBEMathUtilities.h"

typedef struct {
	vector_float4 position;
	vector_float4 color;
} MBECubeVertex;

typedef struct {
	matrix_float4x4 modelViewProjectionMatrix;
} MBECubeUniforms;

@interface MBECube ()

@property (readonly) id <MTLRenderPipelineState> renderPipelineState;

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;
@property id<MTLBuffer> uniformsBuffer;

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
	static const MBECubeVertex vertices[] =
	{
		{ .position = { -1,  1,  1, 1 }, .color = { 0, 1, 1, 1 } },
		{ .position = { -1, -1,  1, 1 }, .color = { 0, 0, 1, 1 } },
		{ .position = {  1, -1,  1, 1 }, .color = { 1, 0, 1, 1 } },
		{ .position = {  1,  1,  1, 1 }, .color = { 1, 1, 1, 1 } },
		{ .position = { -1,  1, -1, 1 }, .color = { 0, 1, 0, 1 } },
		{ .position = { -1, -1, -1, 1 }, .color = { 0, 0, 0, 1 } },
		{ .position = {  1, -1, -1, 1 }, .color = { 1, 0, 0, 1 } },
		{ .position = {  1,  1, -1, 1 }, .color = { 1, 1, 0, 1 } }
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

	self.uniformsBuffer = [self.device newBufferWithLength:sizeof(MBECubeUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.uniformsBuffer setLabel:@"Uniforms"];
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
	[renderCommandEncoder setRenderPipelineState:self.renderPipelineState];

	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
	[renderCommandEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:1];

	[renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
									 indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
									  indexType:MBEIndexType
									indexBuffer:self.indexBuffer
							  indexBufferOffset:0];
}

- (void) updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView viewToProjection:(matrix_float4x4)viewToProjection cameraPosition:(vector_float4)cameraPosition {
	matrix_float4x4 viewProjectionMatrix = matrix_multiply(viewToProjection, worldToView);
	vector_float3 position = {self.x, self.y, self.z};
	const matrix_float4x4 positionMatrix = matrix_float4x4_translation(position);
	const matrix_float4x4 modelMatrix = positionMatrix;

	MBECubeUniforms uniforms;
	uniforms.modelViewProjectionMatrix = matrix_multiply(viewProjectionMatrix, modelMatrix);

	memcpy([self.uniformsBuffer contents], &uniforms, sizeof(uniforms));
}


@end
