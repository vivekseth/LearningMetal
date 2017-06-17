//
//  MBERenderer.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBERenderer.h"
#import "MBEMathUtilities.h"
#import "MBEShaderStructs.h"

@interface MBERenderer ()

@property (readonly) id<MTLDevice> device;

@property (readonly) id <MTLRenderPipelineState> pointLightRenderPipelineState;
@property (readonly) id <MTLRenderPipelineState> objectRenderPipelineState;

@property (strong) id<MTLTexture> depthTexture;

@property (readonly) id<MTLCommandQueue> commandQueue;
@property (strong) id<MTLDepthStencilState> depthStencilState;

@property (strong) dispatch_semaphore_t displaySemaphore;

@property id<MTLBuffer> fragmentLightUniformsBuffer;

@property id<MTLBuffer> vertexSceneUniformsBuffer;

@property (nonatomic, readonly) matrix_float4x4 viewToProjectionMatrix;

@end

@implementation MBERenderer

- (instancetype)initWithSize:(CGSize)size device:(id<MTLDevice>)device;
{
	self = [super init];

	_displaySemaphore = dispatch_semaphore_create(1);

	_device = device;
	_commandQueue = [self.device newCommandQueue];

	[self makePipelines];
	[self makeBuffers];
	[self makeDepthStencilState];
	[self makeDepthTextureForDrawableSize:size];
	[self makeProjectionMatrixForDrawableSize:size];

	return self;
}

- (void)makePipelines
{
	id<MTLLibrary> library = [self.device newDefaultLibrary];

	MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"multiple_lights_vertex_projection"];
	pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"multiple_lights_fragment"];
	pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

	NSError *error = nil;
	_objectRenderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
	if (!self.objectRenderPipelineState)
	{
		NSLog(@"Error occurred when creating render pipeline state: %@", error);
	}


	pipelineDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"simple_vertex_projection"];
	pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"simple_fragment"];
	pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

	error = nil;
	_pointLightRenderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
	if (!self.pointLightRenderPipelineState)
	{
		NSLog(@"Error occurred when creating render pipeline state: %@", error);
	}
}

- (void)makeBuffers
{
	self.fragmentLightUniformsBuffer = [self.device newBufferWithLength:sizeof(MBEFragmentLightUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.fragmentLightUniformsBuffer setLabel:@"fragmentLightUniformsBuffer"];

	self.vertexSceneUniformsBuffer = [self.device newBufferWithLength:sizeof(MBEVertexSceneUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexSceneUniformsBuffer setLabel:@"vertexSceneUniformsBuffer"];
}

- (void)makeDepthStencilState
{
	MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
	depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
	depthStencilDescriptor.depthWriteEnabled = YES;
	self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
}

- (void)makeDepthTextureForDrawableSize:(CGSize)drawableSize
{
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

- (void)makeProjectionMatrixForDrawableSize:(CGSize)drawableSize
{
	const float aspect = drawableSize.width / drawableSize.height;
	const float fov = (2 * M_PI) / 5;
	const float near = 1;
	const float far = 100;
	_viewToProjectionMatrix = matrix_float4x4_perspective(aspect, fov, near, far);
}

- (void)updateFragmentLightUniformsBufferWithLightSources:(NSArray <id<MBEPointLightSource>> *)lightSources viewPosition:(vector_float4)viewPosition
{
	MBEFragmentLightUniforms lightUniforms = {0};
	lightUniforms.viewPosition = viewPosition;
	lightUniforms.numPointLights = (int)lightSources.count;

	for (int i=0; i<lightSources.count; i++) {
		id<MBEPointLightSource> lightSource = lightSources[i];

		MBEFragmentPointLight pointLight = {0};
		pointLight.position = (vector_float4){lightSource.x, lightSource.y, lightSource.z, 1};
		pointLight.color = lightSource.color;
		pointLight.strength = lightSource.strength;
		pointLight.K = lightSource.K;
		pointLight.L = lightSource.L;
		pointLight.Q = lightSource.Q;

		lightUniforms.pointLights[i] = pointLight;
	}

	memcpy([self.fragmentLightUniformsBuffer contents], &lightUniforms, sizeof(lightUniforms));
}

- (void)updateVertexSceneUniformsBufferWithWorldToView:(matrix_float4x4)worldToView viewToProjection:(matrix_float4x4)viewToProjection
{
	MBEVertexSceneUniforms sceneUniforms = {0};

	sceneUniforms.worldToView = worldToView;
	sceneUniforms.viewToProjection = viewToProjection;

	memcpy([self.vertexSceneUniformsBuffer contents], &sceneUniforms, sizeof(sceneUniforms));
}

- (void)drawableSizeWillChange:(CGSize)size
{
	[self makeDepthTextureForDrawableSize:size];
	[self makeProjectionMatrixForDrawableSize:size];
}

- (void)blockUntilNextRender
{
	dispatch_semaphore_wait(self.displaySemaphore, DISPATCH_TIME_FOREVER);
}

- (void)renderObjects:(NSArray <id<MBEObject>> *)objects
		 lightSources:(NSArray <id<MBEPointLightSource>> *)lightSources
		 viewPosition:(vector_float4)viewPosition
		  worldToView:(matrix_float4x4)worldToView
			  MTKView:(MTKView *)view
{

	// Update state
	[self updateVertexSceneUniformsBufferWithWorldToView:worldToView viewToProjection:self.viewToProjectionMatrix];
	[self updateFragmentLightUniformsBufferWithLightSources:lightSources viewPosition:viewPosition];

	// Begin Rendering...
	id<CAMetalDrawable> drawable = [view currentDrawable];
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

	id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

	[renderCommandEncoder setDepthStencilState:self.depthStencilState];
	[renderCommandEncoder setCullMode:MTLCullModeBack];
	[renderCommandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];

	// TODO(vivek): I'm assuming that this state persists across pipelines.
	[renderCommandEncoder setVertexBuffer:self.vertexSceneUniformsBuffer offset:0 atIndex:0];
	[renderCommandEncoder setFragmentBuffer:self.fragmentLightUniformsBuffer offset:0 atIndex:0];

//	// Render objects
	[renderCommandEncoder setRenderPipelineState:self.objectRenderPipelineState];
	for (id <MBEObject> obj in objects) {
		[obj encodeRenderCommand:renderCommandEncoder];
	}

	// Render lights
	[renderCommandEncoder setRenderPipelineState:self.pointLightRenderPipelineState];
	for (id <MBEPointLightSource> lightSource in lightSources) {
		[lightSource encodeRenderCommand:renderCommandEncoder];
	}

	// End Rendering and send draw command.
	[renderCommandEncoder endEncoding];
	[commandBuffer presentDrawable:drawable];
	[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
		dispatch_semaphore_signal(self.displaySemaphore);
	}];
	[commandBuffer commit];
}

@end
