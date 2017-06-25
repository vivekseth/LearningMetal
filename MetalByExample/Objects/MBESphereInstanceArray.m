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

@interface _MBEObjectInstance : NSObject <MBEObject>
@property (nonatomic) void *vertexObjectUniformsBufferPointer;
- (instancetype)initWithVertexObjectUniformsBufferPointer:(void *)vertexObjectUniformsBufferPointer;
@end

@implementation _MBEObjectInstance
@synthesize device, x, y, z, scale;
- (instancetype)initWithVertexObjectUniformsBufferPointer:(void *)vertexObjectUniformsBufferPointer
{
	self = [super init];

	_vertexObjectUniformsBufferPointer = vertexObjectUniformsBufferPointer;

	return self;
}
- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder
{
	// Not Needed for instance. 
}
- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView
{
	const matrix_float4x4 positionMatrix = matrix_float4x4_translation((vector_float3){self.x, self.y, self.z});
	const matrix_float4x4 scaleMatrix = matrix_float4x4_uniform_scale(self.scale);
	const matrix_float4x4 modelToWorld = matrix_multiply(positionMatrix, scaleMatrix);

	MBEVertexObjectUniforms uniforms;
	uniforms.modelToWorld = modelToWorld;

	matrix_float4x4 modelToView = modelToWorld;

	matrix_float3x3 initialNormalMatrix = {
		.columns[0] = modelToView.columns[0].xyz,
		.columns[1] = modelToView.columns[1].xyz,
		.columns[2] = modelToView.columns[2].xyz,
	};
	uniforms.normalMatrix = simd_transpose(simd_inverse(initialNormalMatrix));

	memcpy(self.vertexObjectUniformsBufferPointer, &uniforms, sizeof(uniforms));
}
@end

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
