//
//  GameViewController.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/7/17.
//  Copyright (c) 2017 Vivek Seth. All rights reserved.
//

#import "GameViewController.h"
#import "MBEMathUtilities.h"

typedef uint16_t MBEIndex;
const MTLIndexType MBEIndexType = MTLIndexTypeUInt16;

typedef struct {
	vector_float4 position;
	vector_float4 color;
} MBEVertex;

typedef struct {
	matrix_float4x4 modelViewProjectionMatrix;
} MBEUniforms;


@interface GameViewController()
@property (readonly, strong) MTKView *metalView;
@property (strong) id<MTLTexture> depthTexture;

@property (readonly) id<MTLDevice> device;

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;
@property id<MTLBuffer> uniformsBuffer;

@property (readonly) id<MTLCommandQueue> commandQueue;
@property (readonly) id <MTLRenderPipelineState> renderPipelineState;
@property (strong) id<MTLDepthStencilState> depthStencilState;

@property (strong) dispatch_semaphore_t displaySemaphore;

@property (assign) float rotationX, rotationY, time;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	_metalView = (MTKView *)self.view;
	self.metalView.delegate = self;
	self.metalView.device = MTLCreateSystemDefaultDevice();
	self.metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;;

	_displaySemaphore = dispatch_semaphore_create(1);
	_device = MTLCreateSystemDefaultDevice();
	[self makeDepthTexture];

	self.time = CACurrentMediaTime();

	[self makePipeline];
	[self makeBuffers];
}

- (void)makePipeline
{
	id<MTLLibrary> library = [self.device newDefaultLibrary];

	MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_project"];
	pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_flatcolor"];
	pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

	MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
	depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
	depthStencilDescriptor.depthWriteEnabled = YES;
	self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];

	NSError *error = nil;
	_renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
																		   error:&error];

	if (!self.renderPipelineState)
	{
		NSLog(@"Error occurred when creating render pipeline state: %@", error);
	}

	_commandQueue = [self.device newCommandQueue];
}

- (void)makeBuffers {
	static const MBEVertex vertices[] =
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

	self.uniformsBuffer = [self.device newBufferWithLength:sizeof(MBEUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.uniformsBuffer setLabel:@"Uniforms"];
}

- (void)makeDepthTexture
{
	CGSize drawableSize = self.metalView.drawableSize;

	if ([self.depthTexture width] != drawableSize.width || [self.depthTexture height] != drawableSize.height)
	{
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
																						width:drawableSize.width
																					   height:drawableSize.height
																					mipmapped:NO];
		desc.storageMode = MTLStorageModePrivate;
		desc.usage = MTLTextureUsageRenderTarget;

		self.depthTexture = [self.device newTextureWithDescriptor:desc];
	}
}

- (void)updateUniformsWithduration:(NSTimeInterval)duration
{
	self.time += duration;
	self.rotationX += duration * (M_PI / 2);
	self.rotationY += duration * (M_PI / 3);
	float scaleFactor = sinf(5 * self.time) * 0.25 + 1;
	const vector_float3 xAxis = { 1, 0, 0 };
	const vector_float3 yAxis = { 0, 1, 0 };
	const matrix_float4x4 xRot = matrix_float4x4_rotation(xAxis, self.rotationX);
	const matrix_float4x4 yRot = matrix_float4x4_rotation(yAxis, self.rotationY);
	const matrix_float4x4 scale = matrix_float4x4_uniform_scale(scaleFactor);
	const matrix_float4x4 modelMatrix = matrix_multiply(matrix_multiply(xRot, yRot), scale);

	const vector_float3 cameraTranslation = { 0, 0, -5 };
	const matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraTranslation);

	const CGSize drawableSize = self.metalView.drawableSize;
	const float aspect = drawableSize.width / drawableSize.height;
	const float fov = (2 * M_PI) / 5;
	const float near = 1;
	const float far = 100;
	const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, fov, near, far);

	MBEUniforms uniforms;
	uniforms.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix));

	memcpy([self.uniformsBuffer contents], &uniforms, sizeof(uniforms));
}

#pragma mark MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
	[self makeDepthTexture];
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
	dispatch_semaphore_wait(self.displaySemaphore, DISPATCH_TIME_FOREVER);

	float duration = CACurrentMediaTime() - self.time;
	[self updateUniformsWithduration:duration];

	id<CAMetalDrawable> drawable = [self.metalView currentDrawable];
	id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

	MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];

	passDescriptor.colorAttachments[0].texture = [drawable texture];
	passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
	passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
	passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;

	passDescriptor.depthAttachment.texture = self.depthTexture;
	passDescriptor.depthAttachment.clearDepth = 1.0;
	passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
	passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;


	id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
	[renderPass setRenderPipelineState:self.renderPipelineState];
	[renderPass setDepthStencilState:self.depthStencilState];
	[renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
	[renderPass setCullMode:MTLCullModeBack];

	[renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
	[renderPass setVertexBuffer:self.uniformsBuffer offset:0 atIndex:1];

	[renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
						   indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
							indexType:MBEIndexType
						  indexBuffer:self.indexBuffer
					indexBufferOffset:0];

	[renderPass endEncoding];

	[commandBuffer presentDrawable:view.currentDrawable];

	[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
		dispatch_semaphore_signal(self.displaySemaphore);
	}];

	[commandBuffer commit];
}

@end
