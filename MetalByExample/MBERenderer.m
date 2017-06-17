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
	pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"lighting_vertex_project"];
	pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"lighting_fragment"];
	pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

	NSError *error = nil;
	_objectRenderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
	if (!self.objectRenderPipelineState)
	{
		NSLog(@"Error occurred when creating render pipeline state: %@", error);
	}


	pipelineDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"lighting_vertex_project"];
	pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"lighting_fragment"];
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

// TODO(vivek): need to get view Position.
- (void)updateFragmentLightUniformsWithLightSources:(NSArray <id<MBEPointLightSource>> *)lightSources viewPosition:(vector_float4)viewPosition
{
	MBEFragmentLightUniforms lightUniforms = {0};
	lightUniforms.viewPosition = viewPosition;
	lightUniforms.numPointLights = lightSources.count;

	for (int i=0; i<lightSources.count; i++) {
		id<MBEPointLightSource> lightSource = lightSources[0];

		MBEFragmentPointLight pointLight = {0};
		pointLight.position = (vector_float4){lightSource.x, lightSource.y, lightSource.z, 1};
		pointLight.color = lightSource.color;
		pointLight.strength = lightSource.strength;
		pointLight.constant = lightSource.constant;
		pointLight.linear = lightSource.linear;
		pointLight.quadratic = lightSource.quadratic;

		lightUniforms.pointLights[i] = pointLight;
	}

	memcpy([self.fragmentLightUniformsBuffer contents], &lightUniforms, sizeof(lightUniforms));
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
			  MTKView:(MTKView *)view
{
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

	// Render lights

	for (id <MBEPointLightSource> lightSource in lightSources) {
		[lightSource encodeRenderCommand:renderCommandEncoder];
	}

	// Render objects

	[renderCommandEncoder setRenderPipelineState:self.objectRenderPipelineState];
	[self updateFragmentLightUniformsWithLightSources:lightSources viewPosition:viewPosition];
	[renderCommandEncoder setFragmentBuffer:self.fragmentLightUniformsBuffer offset:0 atIndex:0];
	for (id <MBEObject> obj in objects) {
		[obj encodeRenderCommand:renderCommandEncoder];
	}

	[renderCommandEncoder endEncoding];

	[commandBuffer presentDrawable:drawable];

	[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
		dispatch_semaphore_signal(self.displaySemaphore);
	}];

	[commandBuffer commit];
}

@end
