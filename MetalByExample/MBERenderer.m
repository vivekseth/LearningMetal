//
//  MBERenderer.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBERenderer.h"
#import "MBEMathUtilities.h"

@interface MBERenderer ()

@property (readonly) id<MTLDevice> device;

@property (strong) id<MTLTexture> depthTexture;

@property (readonly) id<MTLCommandQueue> commandQueue;
@property (readonly) id <MTLRenderPipelineState> renderPipelineState;
@property (strong) id<MTLDepthStencilState> depthStencilState;

@property (strong) dispatch_semaphore_t displaySemaphore;

@end

@implementation MBERenderer

- (instancetype)initWithSize:(CGSize)size device:(id<MTLDevice>)device;
{
	self = [super init];

	_displaySemaphore = dispatch_semaphore_create(1);
	_device = device;

	[self makePipeline];
	[self makeDepthTextureForDrawableSize:size];
	[self makeTransformationMatrixForDrawableSize:size];

	return self;
}

- (void)makePipeline
{
	_commandQueue = [self.device newCommandQueue];

	MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
	depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
	depthStencilDescriptor.depthWriteEnabled = YES;
	self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];

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

- (void)makeTransformationMatrixForDrawableSize:(CGSize)drawableSize
{
	const vector_float3 cameraTranslation = { 0, 0, -5 };
	const matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraTranslation);

	const float aspect = drawableSize.width / drawableSize.height;
	const float fov = (2 * M_PI) / 5;
	const float near = 1;
	const float far = 100;
	const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, fov, near, far);

	const matrix_float4x4 viewProjectionMatrix = matrix_multiply(projectionMatrix, viewMatrix);

	_viewProjectionMatrix = viewProjectionMatrix;
}

- (void)drawableSizeWillChange:(CGSize)size
{
	[self makeDepthTextureForDrawableSize:size];
	[self makeTransformationMatrixForDrawableSize:size];
}

- (void)blockUntilNextRender
{
	dispatch_semaphore_wait(self.displaySemaphore, DISPATCH_TIME_FOREVER);
}

- (void)renderObjects:(NSArray <id<MBEObject>> *)objects MTKView:(MTKView *)view
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

	// Draw objects

	/*
	// TODO(vivek): consider splitting objects into two classes. the model object and singleton renderer. The singleton renderer is responsible for setting render state whilst model objects are responsible for uploading whatever data they need to render.
	 ideally this becomes;
	 for object_renderer in object_types:
		 object_renderer set state
		 for object in objects of type:
			 object draw
	 */

	for (MBECube *cube in objects) {
		[cube encodeRenderCommand:renderCommandEncoder];
	}

	// end

	[renderCommandEncoder endEncoding];

	[commandBuffer presentDrawable:drawable];

	[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
		dispatch_semaphore_signal(self.displaySemaphore);
	}];

	[commandBuffer commit];
}

@end
