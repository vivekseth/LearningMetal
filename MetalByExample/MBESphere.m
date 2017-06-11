//
//  MBESphere.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/10/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBESphere.h"

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

- (MBESphereVertex *)createNormalizeSphereVerticesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians outNumVertices:(NSUInteger *)outNumVertices;
{
	NSUInteger numVertices = 2 + meridians * parallels;
	printf("P=%f, M=%f, numVerticies=%d\n", (float)parallels, (float)meridians, (int)numVertices);

	MBESphereVertex *vertices = calloc(numVertices, sizeof(MBESphereVertex));
	MBESphereVertex firstPoint = {
		.position = {0, 0, 1, 1},
		.color = {1, 1, 1, 1}
	};
	MBESphereVertex lastPoint = {
		.position = {0, 0, -1, 1},
		.color = {0, 0, 0, 1}
	};

	vertices[0] = firstPoint;
	vertices[numVertices - 1] = lastPoint;

	for (int i=1; i<(parallels + 1); i++) {
		// Slicing sphere along a meridian results in circle divided into parallels + 2 segments.
		// First and last segments are the poles.
		CGFloat radians = (float)i/(float)(2 * parallels + 2) * 2 * M_PI;
		printf("radians: %f\n", (float)radians);
		NSAssert(radians < (2 * M_PI), @"radians must be less than 2 pi");

		CGFloat radius = sin(radians);
		CGFloat zOffset = cos(radians);

		printf("buffer + index(%d)\n", (int)(1 + (i - 1)*meridians));
		[self generateVerticesForRingWithRadius:radius zOffset:zOffset numDivisions:meridians buffer:(vertices + 1 + (i - 1)*meridians)];
	}

	*outNumVertices = numVertices;
	return vertices;
}

- (void)generateVerticesForRingWithRadius:(CGFloat)radius zOffset:(CGFloat)zOffset numDivisions:(NSUInteger)numDivisions buffer:(MBESphereVertex *)buffer
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
		buffer[i] = point;
	}
}

- (MBEIndex *)createNormalizeSphereIndicesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians outNumIndices:(NSUInteger *)outNumIndices;
{
	NSUInteger numTrianglesNearPoles = 2 * meridians;
	NSUInteger numTrianglesForParallelRows = 2 * meridians * (parallels - 1);
	NSUInteger numTrianges = numTrianglesNearPoles + numTrianglesForParallelRows;

	NSUInteger numIndices = numTrianges * 3;
	MBEIndex *indices = calloc(numIndices, sizeof(MBEIndex));
	NSUInteger indicesIndex = 0;

	// calculate triangles near top pole
	for (int i=0; i<meridians; i++) {
		// TODO(vivek): make sure handedness matches
		indices[indicesIndex + 1] = [self indexForSpherePointAtParallelIndex:0 meridianIndex:i   parallels:parallels meridians:meridians];
		indices[indicesIndex + 0] = [self indexForSpherePointAtParallelIndex:1 meridianIndex:i   parallels:parallels meridians:meridians];
		indices[indicesIndex + 2] = [self indexForSpherePointAtParallelIndex:1 meridianIndex:i+1 parallels:parallels meridians:meridians];
		indicesIndex += 3;
	}

	// calculate triangles near bottom pole
	for (int i=0; i<meridians; i++) {
		// TODO(vivek): make sure handedness matches
		indices[indicesIndex + 2] = [self indexForSpherePointAtParallelIndex:parallels+1 meridianIndex:i   parallels:parallels meridians:meridians];
		indices[indicesIndex + 0] = [self indexForSpherePointAtParallelIndex:parallels   meridianIndex:i   parallels:parallels meridians:meridians];
		indices[indicesIndex + 1] = [self indexForSpherePointAtParallelIndex:parallels   meridianIndex:i+1 parallels:parallels meridians:meridians];

		indicesIndex += 3;
	}

	// Next calculate triangles for rows
	for (int p=1; p<parallels+1; p++) {
		for (int m=0; m<meridians; m++) {
			// TODO(vivek): make sure handedness matches
			indices[indicesIndex + 0] = [self indexForSpherePointAtParallelIndex:p meridianIndex:m parallels:parallels meridians:meridians];
			indices[indicesIndex + 1] = [self indexForSpherePointAtParallelIndex:p meridianIndex:m+1 parallels:parallels meridians:meridians];
			indices[indicesIndex + 2] = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m parallels:parallels meridians:meridians];
			indicesIndex += 3;

			indices[indicesIndex + 2] = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m+1 parallels:parallels meridians:meridians];
			indices[indicesIndex + 1] = [self indexForSpherePointAtParallelIndex:p meridianIndex:m+1 parallels:parallels meridians:meridians];
			indices[indicesIndex + 0] = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m parallels:parallels meridians:meridians];
			indicesIndex += 3;
		}
	}

	*outNumIndices = numIndices;
	return indices;
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
	NSUInteger numVertices = 0;
	MBESphereVertex *vertices = [self createNormalizeSphereVerticesWithParallels:parallels meridians:meridians outNumVertices:&numVertices];
	self.vertexBuffer = [self.device newBufferWithBytes:vertices length:numVertices * sizeof(MBESphereVertex) options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];
	free(vertices);

	NSUInteger numIndices = 0;
	MBEIndex *indices = [self createNormalizeSphereIndicesWithParallels:parallels meridians:meridians outNumIndices:&numIndices];
	self.indexBuffer = [self.device newBufferWithBytes:indices length:numIndices * sizeof(MBEIndex) options:MTLResourceOptionCPUCacheModeDefault];
	[self.indexBuffer setLabel:@"Indices"];
	free(indices);

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

- (void) updateWithTime:(CGFloat)time duration:(CGFloat)duration viewProjectionMatrix:(matrix_float4x4)viewProjectionMatrix {
	float rotationX = time * (M_PI / 2);
	float rotationY = time * (M_PI / 3);
	float scaleFactor = 1.2;
	const vector_float3 xAxis = { 1, 0, 0 };
	const vector_float3 yAxis = { 0, 1, 0 };

	vector_float3 position = {self.x, self.y, self.z};
	const matrix_float4x4 positionMatrix = matrix_float4x4_translation(position);
	const matrix_float4x4 xRot = matrix_float4x4_rotation(xAxis, rotationX);
	const matrix_float4x4 yRot = matrix_float4x4_rotation(yAxis, rotationY);
	const matrix_float4x4 scale = matrix_float4x4_uniform_scale(scaleFactor);
	const matrix_float4x4 modelMatrix = matrix_multiply(positionMatrix, matrix_multiply(matrix_multiply(xRot, yRot), scale));

	MBESphereUniforms uniforms;
	uniforms.modelViewProjectionMatrix = matrix_multiply(viewProjectionMatrix, modelMatrix);

	memcpy([self.uniformsBuffer contents], &uniforms, sizeof(uniforms));
}

@end
