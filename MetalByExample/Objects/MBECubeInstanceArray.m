//
//  MBECubeInstanceArray.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/25/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBECubeInstanceArray.h"
#import "_MBEObjectInstance.h"

@interface MBECubeInstanceArray ()

@property id<MTLBuffer> vertexBuffer;

// This buffer can be modified by instances.
@property id<MTLBuffer> vertexObjectUniformsBuffer;
@property id<MTLBuffer> fragmentMaterialUniformsBuffer;
@property (nonatomic, strong) NSArray <_MBEObjectInstance *> *objectInstances;

@end

@implementation MBECubeInstanceArray

@synthesize device, x, y, z, scale;

- (instancetype)initWithDevice:(id<MTLDevice>)device instanceCount:(NSUInteger)instanceCount
{
	self = [super init];

	_instanceCount = instanceCount;
	self.device = device;

	[self makeBuffers];

	NSMutableArray *objectInstances = [NSMutableArray array];
	MBEVertexObjectUniforms *vertexObjectUniformsBuffer = (MBEVertexObjectUniforms *)[self.vertexObjectUniformsBuffer contents];
	for (NSUInteger i=0; i<self.instanceCount; i++) {
		_MBEObjectInstance *instance = [[_MBEObjectInstance alloc] initWithVertexObjectUniformsBufferPointer:(vertexObjectUniformsBuffer + i)];
		[objectInstances addObject:instance];
	}
	_objectInstances = [NSArray arrayWithArray:objectInstances];

	return self;
}

- (void)makeBuffers {
	static const MBEVertexIn vertices[] =
	{
		{.position = { -0.5f,  -0.5f,  -0.5f, 1 }, .color = { 0, 0, 1, 0 }, .normal = {0.0f, 0.0f, -1.0f}},
		{.position = { 0.5f,  0.5f,  -0.5f, 1 }, .color = { 0, 0, 1, 0 }, .normal = {0.0f, 0.0f, -1.0f}},
		{.position = { 0.5f,  -0.5f,  -0.5f, 1 }, .color = { 0, 0, 1, 0 }, .normal = {0.0f, 0.0f, -1.0f}},
		{.position = { -0.5f,  0.5f,  -0.5f, 1 }, .color = { 0, 0, 1, 0 }, .normal = {0.0f, 0.0f, -1.0f}},
		{.position = { 0.5f,  0.5f,  -0.5f, 1 }, .color = { 0, 0, 1, 0 }, .normal = {0.0f, 0.0f, -1.0f}},
		{.position = { -0.5f,  -0.5f,  -0.5f, 1 }, .color = { 0, 0, 1, 0 }, .normal = {0.0f, 0.0f, -1.0f}},

		{.position = { -0.5f,  -0.5f,  0.5f, 1 }, .color = { 1, 1, 0, 0 }, .normal = {0.0f, 0.0f, 1.0f}},
		{.position = { 0.5f,  -0.5f,  0.5f, 1 }, .color = { 1, 1, 0, 0 }, .normal = {0.0f, 0.0f, 1.0f}},
		{.position = { 0.5f,  0.5f,  0.5f, 1 }, .color = { 1, 1, 0, 0 }, .normal = {0.0f, 0.0f, 1.0f}},
		{.position = { 0.5f,  0.5f,  0.5f, 1 }, .color = { 1, 1, 0, 0 }, .normal = {0.0f, 0.0f, 1.0f}},
		{.position = { -0.5f,  0.5f,  0.5f, 1 }, .color = { 1, 1, 0, 0 }, .normal = {0.0f, 0.0f, 1.0f}},
		{.position = { -0.5f,  -0.5f,  0.5f, 1 }, .color = { 1, 1, 0, 0 }, .normal = {0.0f, 0.0f, 1.0f}},

		{.position = { -0.5f,  0.5f,  0.5f, 1 }, .color = { 0, 1, 0, 0 }, .normal = {-1.0f, 0.0f, 0}},
		{.position = { -0.5f,  0.5f,  -0.5f, 1 }, .color = { 0, 1, 0, 0 }, .normal = {-1.0f, 0.0f, 0}},
		{.position = { -0.5f,  -0.5f,  -0.5f, 1 }, .color = { 0, 1, 0, 0 }, .normal = {-1.0f, 0.0f, 0}},
		{.position = { -0.5f,  -0.5f,  -0.5f, 1 }, .color = { 0, 1, 0, 0 }, .normal = {-1.0f, 0.0f, 0}},
		{.position = { -0.5f,  -0.5f,  0.5f, 1 }, .color = { 0, 1, 0, 0 }, .normal = {-1.0f, 0.0f, 0}},
		{.position = { -0.5f,  0.5f,  0.5f, 1 }, .color = { 0, 1, 0, 0 }, .normal = {-1.0f, 0.0f, 0}},

		{.position = { 0.5f,  0.5f,  -0.5f, 1 }, .color = { 1, 0, 1, 0 }, .normal = {1.0f, 0.0f, 0}},
		{.position = { 0.5f,  0.5f,  0.5f, 1 }, .color = { 1, 0, 1, 0 }, .normal = {1.0f, 0.0f, 0}},
		{.position = { 0.5f,  -0.5f,  -0.5f, 1 }, .color = { 1, 0, 1, 0 }, .normal = {1.0f, 0.0f, 0}},
		{.position = { 0.5f,  -0.5f,  0.5f, 1 }, .color = { 1, 0, 1, 0 }, .normal = {1.0f, 0.0f, 0}},
		{.position = { 0.5f,  -0.5f,  -0.5f, 1 }, .color = { 1, 0, 1, 0 }, .normal = {1.0f, 0.0f, 0}},
		{.position = { 0.5f,  0.5f,  0.5f, 1 }, .color = { 1, 0, 1, 0 }, .normal = {1.0f, 0.0f, 0}},

		{.position = { -0.5f,  -0.5f,  -0.5f, 1 }, .color = { 1, 0, 0, 0 }, .normal = {0.0f, -1.0f, 0}},
		{.position = { 0.5f,  -0.5f,  -0.5f, 1 }, .color = { 1, 0, 0, 0 }, .normal = {0.0f, -1.0f, 0}},
		{.position = { 0.5f,  -0.5f,  0.5f, 1 }, .color = { 1, 0, 0, 0 }, .normal = {0.0f, -1.0f, 0}},
		{.position = { 0.5f,  -0.5f,  0.5f, 1 }, .color = { 1, 0, 0, 0 }, .normal = {0.0f, -1.0f, 0}},
		{.position = { -0.5f,  -0.5f,  0.5f, 1 }, .color = { 1, 0, 0, 0 }, .normal = {0.0f, -1.0f, 0}},
		{.position = { -0.5f,  -0.5f,  -0.5f, 1 }, .color = { 1, 0, 0, 0 }, .normal = {0.0f, -1.0f, 0}},

		{.position = { -0.5f,  0.5f,  -0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { 0.5f,  0.5f,  0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { 0.5f,  0.5f,  -0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { 0.5f,  0.5f,  0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { -0.5f,  0.5f,  -0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
		{.position = { -0.5f,  0.5f,  0.5f, 1 }, .color = { 0, 1, 1, 0 }, .normal = {0.0f, 1.0f, 0}},
	};

	self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];

	self.vertexObjectUniformsBuffer = [self.device newBufferWithLength:self.instanceCount * sizeof(MBEVertexObjectUniforms) options:MTLResourceOptionCPUCacheModeDefault];
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

- (id<MBEObject>)objectAtIndexedSubscript:(NSUInteger)idx
{
	return self.objectInstances[idx];
}

#pragma mark <MBEObject>

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder {
	[renderCommandEncoder setVertexBuffer:self.vertexObjectUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
	[renderCommandEncoder setFragmentBuffer:self.fragmentMaterialUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
							 vertexStart:0
							 vertexCount:36
						   instanceCount:self.instanceCount];

}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView {
	for (_MBEObjectInstance *objectInstance in self.objectInstances) {
		[objectInstance updateWithTime:time duration:duration worldToView:worldToView];
	}
}

@end
