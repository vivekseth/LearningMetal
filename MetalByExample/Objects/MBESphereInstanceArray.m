//
//  MBESphereInstanceArray.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/25/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBESphereInstanceArray.h"
#import "MBESphere.h"
#import "MBEObject.h"
#import "MBESphereUtility.h"
#import "_MBEObjectInstance.h"


@interface MBESphereInstanceArray ()

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;

// This buffer can be modified by instances.
@property id<MTLBuffer> vertexObjectUniformsBuffer;
@property id<MTLBuffer> fragmentMaterialUniformsBuffer;
@property (nonatomic, strong) NSArray <_MBEObjectInstance *> *objectInstances;

@end

@implementation MBESphereInstanceArray

@synthesize device, x, y, z, scale;

- (instancetype)initWithDevice:(id<MTLDevice>)device instanceCount:(NSUInteger)instanceCount parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	self = [super init];

	_instanceCount = instanceCount;
	self.device = device;

	[self makeBuffersWithParallels:parallels meridians:meridians];

	NSMutableArray *objectInstances = [NSMutableArray array];
	MBEVertexObjectUniforms *vertexObjectUniformsBuffer = (MBEVertexObjectUniforms *)[self.vertexObjectUniformsBuffer contents];
	for (NSUInteger i=0; i<self.instanceCount; i++) {
		_MBEObjectInstance *instance = [[_MBEObjectInstance alloc] initWithVertexObjectUniformsBufferPointer:(vertexObjectUniformsBuffer + i)];
		[objectInstances addObject:instance];
	}
	_objectInstances = [NSArray arrayWithArray:objectInstances];

	return self;
}

- (void)makeBuffersWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians {
	MBESafeArray vertices = [MBESphereUtility createNormalizeSphereVerticesWithParallels:parallels meridians:meridians];
	self.vertexBuffer = [self.device newBufferWithBytes:vertices.pointer length:vertices.count * vertices.size options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];
	MBESafeArrayFree(vertices);

	MBESafeArray indices = [MBESphereUtility createNormalizeSphereIndicesWithParallels:parallels meridians:meridians];
	self.indexBuffer = [self.device newBufferWithBytes:indices.pointer length:indices.count * indices.size options:MTLResourceOptionCPUCacheModeDefault];
	[self.indexBuffer setLabel:@"Indices"];
	MBESafeArrayFree(indices);

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
	[renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
									 indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
									  indexType:MBEIndexType
									indexBuffer:self.indexBuffer
							  indexBufferOffset:0
								  instanceCount:self.instanceCount];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView {
	for (_MBEObjectInstance *objectInstance in self.objectInstances) {
		[objectInstance updateWithTime:time duration:duration worldToView:worldToView];
	}
}

@end
