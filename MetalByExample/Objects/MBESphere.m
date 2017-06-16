//
//  MBESphere.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/10/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBESphere.h"
#import "MBESafeArray.h"

typedef struct {
	vector_float4 position;
	vector_float4 color;
} MBESphereVertex;

typedef struct {
	matrix_float4x4 modelViewProjectionMatrix;
} MBESphereUniforms;


@interface MBESphere ()

@property (readonly) id <MTLRenderPipelineState> renderPipelineState;

@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;
@property id<MTLBuffer> uniformsBuffer;

@end


@implementation MBESphere

@synthesize device, x, y, z;

- (instancetype) initWithDevice:(id<MTLDevice>)device parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	self = [super init];

	self.device = device;

	[self makePipeline];
	[self makeBuffersWithParallels:parallels meridians:meridians];

	return self;
}

- (MBESafeArray)createNormalizeSphereVerticesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	NSUInteger numVertices = 2 + meridians * parallels;
	printf("P=%f, M=%f, numVerticies=%d\n", (float)parallels, (float)meridians, (int)numVertices);

	MBESafeArray verticesArr = MBESafeArrayCreate(numVertices, sizeof(MBESphereVertex));

	MBESphereVertex firstPoint = {
		.position = {0, 0, 1, 1},
		.color = {1, 1, 1, 1}
	};
	MBESphereVertex lastPoint = {
		.position = {0, 0, -1, 1},
		.color = {0, 0, 0, 1}
	};

	*((MBESphereVertex *)MBESafeArrayGetPointer(verticesArr, 0)) = firstPoint;
	*((MBESphereVertex *)MBESafeArrayGetPointer(verticesArr, numVertices - 1)) = lastPoint;

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

		MBESphereVertex point = {
			.position = {x, y, zOffset, 1},
			.color = {r, g, b, 1}
		};

		printf("+ %d\n", (int)i);
		*((MBESphereVertex *)MBESafeArrayGetPointer(array, i)) = point;
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

	self.uniformsBuffer = [self.device newBufferWithLength:sizeof(MBESphereUniforms) options:MTLResourceOptionCPUCacheModeDefault];
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

- (void) encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder {
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

	MBESphereUniforms uniforms;
	uniforms.modelViewProjectionMatrix = matrix_multiply(viewProjectionMatrix, modelMatrix);

	memcpy([self.uniformsBuffer contents], &uniforms, sizeof(uniforms));

}

@end