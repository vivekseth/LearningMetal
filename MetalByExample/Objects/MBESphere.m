//
//  MBELightingSphere.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/10/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBESphere.h"
#import "MBESphereUtility.h"

@interface MBESphere ()

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;

@property id<MTLBuffer> vertexObjectUniformsBuffer;
@property id<MTLBuffer> fragmentMaterialUniformsBuffer;

@end

@implementation MBESphere

@synthesize device, x, y, z, scale;

- (instancetype) initWithDevice:(id<MTLDevice>)device parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	self = [super init];

	self.device = device;
	self.scale = 1.0;

	[self makeBuffersWithParallels:parallels meridians:meridians];

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

	self.vertexObjectUniformsBuffer = [self.device newBufferWithLength:sizeof(MBEVertexObjectUniforms) options:MTLResourceOptionCPUCacheModeDefault];
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

#pragma mark <MBEObject>

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder {
	[renderCommandEncoder setVertexBuffer:self.vertexObjectUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
	[renderCommandEncoder setFragmentBuffer:self.fragmentMaterialUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
									 indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
									  indexType:MBEIndexType
									indexBuffer:self.indexBuffer
							  indexBufferOffset:0];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView
{
	const matrix_float4x4 positionMatrix = matrix_float4x4_translation((vector_float3){self.x, self.y, self.z});
    const matrix_float4x4 scaleMatrix = matrix_float4x4_uniform_scale(self.scale);
    const matrix_float4x4 modelToWorld = matrix_multiply(positionMatrix, scaleMatrix);

	MBEVertexObjectUniforms uniforms;
	uniforms.modelToWorld = modelToWorld;

	matrix_float4x4 modelToView = modelToWorld; // matrix_multiply(worldToView, modelToWorld);

	matrix_float3x3 initialNormalMatrix = {
		.columns[0] = modelToView.columns[0].xyz,
		.columns[1] = modelToView.columns[1].xyz,
		.columns[2] = modelToView.columns[2].xyz,
	};
	uniforms.normalMatrix = simd_transpose(simd_inverse(initialNormalMatrix));

	memcpy([self.vertexObjectUniformsBuffer contents], &uniforms, sizeof(uniforms));
}

@end
