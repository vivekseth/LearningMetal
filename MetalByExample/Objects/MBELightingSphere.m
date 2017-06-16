//
//  MBELightingSphere.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/10/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBELightingSphere.h"
#import "MBESafeArray.h"

typedef struct {
	vector_float4 position;
	vector_float4 color;
	vector_float3 normal;
} MBELightingSphereVertex;

typedef struct {
	matrix_float4x4 modelToWorld;
	matrix_float4x4 worldToView;
	matrix_float4x4 viewToProjection;
	matrix_float3x3 normalMatrix;
} MBELightingSphereVertexUniforms;

/*

 struct FragmentMaterialUniforms
 {
 float4 objectColor;
 float ambientStrength;
 float diffuseStrength;
 float specularStrength;
 float specularFactor;
 };

 struct FragmentLightUniforms
 {
 float4 viewPosition; // camera position
 float4 lightPosition;
 float4 lightColor;
 };

 */

typedef struct {
	vector_float4 viewPosition;
	vector_float4 lightPosition;
	vector_float4 lightColor;
} MBELightingSphereFragmentLightUniforms;



@interface MBELightingSphere ()

@property (readonly) id <MTLRenderPipelineState> renderPipelineState;

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;
@property id<MTLBuffer> vertexUniformsBuffer;
@property id<MTLBuffer> fragmentUniformsMaterialBuffer;
@property id<MTLBuffer> fragmentUniformsLightBuffer;

@end


@implementation MBELightingSphere

@synthesize device, x, y, z;

- (instancetype) initWithDevice:(id<MTLDevice>)device parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	self = [super init];

	self.device = device;

    MBELightingSphereFragmentMaterialUniforms fragmentMaterialUniforms;
    fragmentMaterialUniforms.objectColor = (vector_float4){1, 1, 1, 1};
    fragmentMaterialUniforms.ambientStrength = 0.3;
    fragmentMaterialUniforms.diffuseStrength = 0.3;
    fragmentMaterialUniforms.specularStrength = 0.5;
    fragmentMaterialUniforms.specularFactor = 32;

    self.material = fragmentMaterialUniforms;

	[self makePipeline];
	[self makeBuffersWithParallels:parallels meridians:meridians];

	return self;
}

- (MBESafeArray)createNormalizeSphereVerticesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	NSUInteger numVertices = 2 + meridians * parallels;
	printf("P=%f, M=%f, numVerticies=%d\n", (float)parallels, (float)meridians, (int)numVertices);

	MBESafeArray verticesArr = MBESafeArrayCreate(numVertices, sizeof(MBELightingSphereVertex));

	MBELightingSphereVertex firstPoint = {
		.position = {0, 0, 1, 1},
		.color = {1, 1, 1, 1},
		.normal = {0, 0, 1}
	};
	MBELightingSphereVertex lastPoint = {
		.position = {0, 0, -1, 1},
		.color = {0, 0, 0, 1},
		.normal = {0, 0, -1}
	};

	*((MBELightingSphereVertex *)MBESafeArrayGetPointer(verticesArr, 0)) = firstPoint;
	*((MBELightingSphereVertex *)MBESafeArrayGetPointer(verticesArr, numVertices - 1)) = lastPoint;

	for (int i=1; i<(parallels + 1); i++) {
		// Slicing sphere along a meridian results in circle divided into parallels + 2 segments.
		// First and last segments are the poles.
		CGFloat radians = (float)i/(float)(2 * parallels + 2) * 2 * M_PI;
		printf("radians: %f\n", (float)radians);
		NSAssert(radians < (2 * M_PI), @"radians must be less than 2 pi");

		CGFloat radius = sin(radians);
		CGFloat zOffset = cos(radians);

		printf("buffer + index(%d)\n", (int)(1 + (i - 1)*meridians));
		MBESafeArray offsetArray = MBESafeArrayCreateOffsetArray(verticesArr, 1 + (i - 1)*meridians);
		[self generateVerticesForRingWithRadius:radius zOffset:zOffset numDivisions:meridians array:offsetArray];
		MBESafeArrayFree(offsetArray);
	}

	return verticesArr;
}

- (void)generateVerticesForRingWithRadius:(CGFloat)radius zOffset:(CGFloat)zOffset numDivisions:(NSUInteger)numDivisions array:(MBESafeArray)array
{
	for (int i=0; i<numDivisions; i++) {
		CGFloat radians = (float)i/(float)numDivisions * 2 * M_PI;

		CGFloat x = cos(radians) * radius;
		CGFloat y = sin(radians) * radius;

		CGFloat grayValue = (zOffset + 1) / 2.0;

		NSColor *c = [NSColor colorWithHue:(float)i/(float)numDivisions saturation:radius brightness:grayValue alpha:1.0];
		CGFloat r, g, b;
		[c getRed:&r green:&g blue:&b alpha:NULL];

		MBELightingSphereVertex point = {
			.position = {x, y, zOffset, 1},
			.color = {r, g, b, 1},
			.normal = {x, y, zOffset}
		};

		printf("+ %d\n", (int)i);
		*((MBELightingSphereVertex *)MBESafeArrayGetPointer(array, i)) = point;
	}
}

- (MBESafeArray)createNormalizeSphereIndicesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	NSUInteger numTrianglesNearPoles = 2 * meridians;
	NSUInteger numTrianglesForParallelRows = 2 * meridians * (parallels - 1);
	NSUInteger numTrianges = numTrianglesNearPoles + numTrianglesForParallelRows;

	NSUInteger numIndices = numTrianges * 3;
	MBESafeArray indicesArr = MBESafeArrayCreate(numIndices, sizeof(MBEIndex));

	NSUInteger indicesIndex = 0;

	// calculate triangles near top pole
	for (int i=0; i<meridians; i++) {
		MBESafeArray offsetArr = MBESafeArrayCreateOffsetArray(indicesArr, indicesIndex);

		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:0 meridianIndex:i   parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:1 meridianIndex:i   parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:1 meridianIndex:i+1 parallels:parallels meridians:meridians];

		MBESafeArrayFree(offsetArr);

		indicesIndex += 3;
	}

	// calculate triangles near bottom pole
	for (int i=0; i<meridians; i++) {
		MBESafeArray offsetArr = MBESafeArrayCreateOffsetArray(indicesArr, indicesIndex);
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:parallels+1 meridianIndex:i   parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:parallels   meridianIndex:i   parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:parallels   meridianIndex:i+1 parallels:parallels meridians:meridians];
		MBESafeArrayFree(offsetArr);

		indicesIndex += 3;
	}

	// Next calculate triangles for rows
	for (int p=1; p<parallels; p++) {
		for (int m=0; m<meridians; m++) {
			MBESafeArray offsetArr = MBESafeArrayCreateOffsetArray(indicesArr, indicesIndex);
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:p meridianIndex:m parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:p meridianIndex:m+1 parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m parallels:parallels meridians:meridians];
			MBESafeArrayFree(offsetArr);

			indicesIndex += 3;

			offsetArr = MBESafeArrayCreateOffsetArray(indicesArr, indicesIndex);
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m+1 parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:p meridianIndex:m+1 parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m parallels:parallels meridians:meridians];
			MBESafeArrayFree(offsetArr);

			indicesIndex += 3;
		}
	}

	return indicesArr;
}

- (NSUInteger)indexForSpherePointAtParallelIndex:(NSUInteger)parallelIndex meridianIndex:(NSUInteger)meridianIndex parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	// pi 0 = top pole
	// pi N + 1 = bottom pole
	// pi 1 <=> N = parallels
	// mi 0 -> INF % numMeridians

	NSAssert(parallelIndex <= parallels + 1, @"parallelIndex must be less than parallels + 1");
	NSAssert(meridianIndex <= meridians, @"every meridianIndex is valid, but if i'm hitting this asset i'm doing something wrong.");

	NSUInteger moduloMeridianIndex = meridianIndex % meridians;
	NSUInteger numVertices = 2 + meridians * parallels;

	if (parallelIndex == 0) {
		return 0;
	}
	else if (parallelIndex == (parallels + 1)) {
		return numVertices - 1;
	}
	else {
		return 1 + ((parallelIndex - 1) * meridians) + moduloMeridianIndex;
	}
}


- (void)makeBuffersWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians {
	MBESafeArray vertices = [self createNormalizeSphereVerticesWithParallels:parallels meridians:meridians];
	self.vertexBuffer = [self.device newBufferWithBytes:vertices.pointer length:vertices.count * vertices.size options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];
	MBESafeArrayFree(vertices);

	MBESafeArray indices = [self createNormalizeSphereIndicesWithParallels:parallels meridians:meridians];
	self.indexBuffer = [self.device newBufferWithBytes:indices.pointer length:indices.count * indices.size options:MTLResourceOptionCPUCacheModeDefault];
	[self.indexBuffer setLabel:@"Indices"];
	MBESafeArrayFree(indices);

	self.vertexUniformsBuffer = [self.device newBufferWithLength:sizeof(MBELightingSphereVertexUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexUniformsBuffer setLabel:@"vertexUniformsBuffer"];

	self.fragmentUniformsMaterialBuffer = [self.device newBufferWithLength:sizeof(MBELightingSphereFragmentMaterialUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.fragmentUniformsMaterialBuffer setLabel:@"fragmentUniformsMaterialBuffer"];

	self.fragmentUniformsLightBuffer = [self.device newBufferWithLength:sizeof(MBELightingSphereFragmentLightUniforms) options:MTLResourceOptionCPUCacheModeDefault];
	[self.fragmentUniformsLightBuffer setLabel:@"fragmentUniformsLightBuffer"];
}

- (void)makePipeline
{
	id<MTLLibrary> library = [self.device newDefaultLibrary];

	MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"lighting_vertex_project"];
	pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"lighting_fragment"];
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

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder {
	[renderCommandEncoder setRenderPipelineState:self.renderPipelineState];

	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
	[renderCommandEncoder setVertexBuffer:self.vertexUniformsBuffer offset:0 atIndex:1];

	[renderCommandEncoder setFragmentBuffer:self.fragmentUniformsMaterialBuffer offset:0 atIndex:0];
	[renderCommandEncoder setFragmentBuffer:self.fragmentUniformsLightBuffer offset:0 atIndex:1];

	[renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
									 indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
									  indexType:MBEIndexType
									indexBuffer:self.indexBuffer
							  indexBufferOffset:0];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView viewToProjection:(matrix_float4x4)viewToProjection cameraPosition:(vector_float4)cameraPosition
{
	[self updateWithTime:time duration:duration worldToView:worldToView viewToProjection:viewToProjection cameraPosition:(vector_float4){5, 5, 0, 1}];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView viewToProjection:(matrix_float4x4)viewToProjection cameraPosition:(vector_float4)cameraPosition lightSourcePosition:(vector_float4)lightSourcePosition
{
	vector_float3 position = {self.x, self.y, self.z};
	const matrix_float4x4 positionMatrix = matrix_float4x4_translation(position);
    const matrix_float4x4 modelToWorld = positionMatrix;

	MBELightingSphereVertexUniforms uniforms;
	uniforms.modelToWorld = modelToWorld;
	uniforms.worldToView = worldToView;
	uniforms.viewToProjection = viewToProjection;

	matrix_float4x4 modelToView = matrix_multiply(worldToView, modelToWorld);

	matrix_float3x3 initialNormalMatrix = {
		.columns[0] = modelToView.columns[0].xyz,
		.columns[1] = modelToView.columns[1].xyz,
		.columns[2] = modelToView.columns[2].xyz,
	};
	uniforms.normalMatrix = simd_transpose(simd_inverse(initialNormalMatrix));

	memcpy([self.vertexUniformsBuffer contents], &uniforms, sizeof(uniforms));

    MBELightingSphereFragmentMaterialUniforms fragmentMaterialUniforms = self.material;

	memcpy([self.fragmentUniformsMaterialBuffer contents], &fragmentMaterialUniforms, sizeof(fragmentMaterialUniforms));

	MBELightingSphereFragmentLightUniforms fragmentLightUniforms;
	fragmentLightUniforms.lightColor = (vector_float4){1, 1, 1, 1};
	fragmentLightUniforms.lightPosition = lightSourcePosition;
	fragmentLightUniforms.viewPosition = cameraPosition;

	memcpy([self.fragmentUniformsLightBuffer contents], &fragmentLightUniforms, sizeof(fragmentLightUniforms));
}

@end
