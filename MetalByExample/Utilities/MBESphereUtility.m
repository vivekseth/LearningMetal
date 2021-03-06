//
//  MBESphereUtility.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/25/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBESphereUtility.h"
#import "MBEMathUtilities.h"
#import "MBEObject.h"
#import <AppKit/AppKit.h>

@implementation MBESphereUtility

+ (void)printSphereDotObjWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	// MBEVertexIn
	MBESafeArray verticesArr = [self.class createNormalizeSphereVerticesWithParallels:parallels meridians:meridians];

	// MBEIndex
	MBESafeArray indicesArr = [self.class createNormalizeSphereIndicesWithParallels:parallels meridians:meridians];

	for (int i=0; i<verticesArr.count; i++) {
		MBEVertexIn vertex = *((MBEVertexIn *)MBESafeArrayGetPointer(verticesArr, i));
		printf("v %f %f %f\n", vertex.position.x, vertex.position.y, vertex.position.z);
	}

	for (int i=0; i<verticesArr.count; i++) {
		MBEVertexIn vertex = *((MBEVertexIn *)MBESafeArrayGetPointer(verticesArr, i));
		printf("vn %f %f %f\n", vertex.normal.x, vertex.normal.y, vertex.normal.z);
	}

	for (int i=0; i<(indicesArr.count/3); i++) {
		MBEIndex *indices = ((MBEIndex *)MBESafeArrayGetPointer(indicesArr, 3 * i));
		int v0 = indices[0] + 1;
		int v1 = indices[1] + 1;
		int v2 = indices[2] + 1;
		printf("f %d//%d %d//%d %d//%d\n", v0, v0, v1, v1, v2, v2);
	}

	MBESafeArrayFree(verticesArr);
	MBESafeArrayFree(indicesArr);
}

+ (MBESafeArray)createNormalizeSphereVerticesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
{
	NSUInteger numVertices = 2 + meridians * parallels;
	// printf("P=%f, M=%f, numVerticies=%d\n", (float)parallels, (float)meridians, (int)numVertices);

	MBESafeArray verticesArr = MBESafeArrayCreate(numVertices, sizeof(MBEVertexIn));

	MBEVertexIn firstPoint = {
		.position = {0, 0, 1, 1},
		.color = {1, 1, 1, 1},
		.normal = {0, 0, 1}
	};
	MBEVertexIn lastPoint = {
		.position = {0, 0, -1, 1},
		.color = {0, 0, 0, 1},
		.normal = {0, 0, -1}
	};

	*((MBEVertexIn *)MBESafeArrayGetPointer(verticesArr, 0)) = firstPoint;
	*((MBEVertexIn *)MBESafeArrayGetPointer(verticesArr, numVertices - 1)) = lastPoint;

	for (int i=1; i<(parallels + 1); i++) {
		// Slicing sphere along a meridian results in circle divided into parallels + 2 segments.
		// First and last segments are the poles.
		CGFloat radians = (float)i/(float)(2 * parallels + 2) * 2 * M_PI;
		// printf("radians: %f\n", (float)radians);
		NSAssert(radians < (2 * M_PI), @"radians must be less than 2 pi");

		CGFloat radius = sin(radians);
		CGFloat zOffset = cos(radians);

		// printf("buffer + index(%d)\n", (int)(1 + (i - 1)*meridians));
		MBESafeArray offsetArray = MBESafeArrayCreateOffsetArray(verticesArr, 1 + (i - 1)*meridians);
		[self generateVerticesForRingWithRadius:radius zOffset:zOffset numDivisions:meridians array:offsetArray];
		MBESafeArrayFree(offsetArray);
	}

	return verticesArr;
}

+ (void)generateVerticesForRingWithRadius:(CGFloat)radius zOffset:(CGFloat)zOffset numDivisions:(NSUInteger)numDivisions array:(MBESafeArray)array
{
	for (int i=0; i<numDivisions; i++) {
		CGFloat radians = (float)i/(float)numDivisions * 2 * M_PI;

		CGFloat x = cos(radians) * radius;
		CGFloat y = sin(radians) * radius;

		CGFloat grayValue = (zOffset + 1) / 2.0;

		NSColor *c = [NSColor colorWithHue:(float)i/(float)numDivisions saturation:radius brightness:grayValue alpha:1.0];
		CGFloat r, g, b;
		[c getRed:&r green:&g blue:&b alpha:NULL];

		MBEVertexIn point = {
			.position = {x, y, zOffset, 1},
			.color = {r, g, b, 1},
			.normal = {x, y, zOffset}
		};

		// printf("+ %d\n", (int)i);
		*((MBEVertexIn *)MBESafeArrayGetPointer(array, i)) = point;
	}
}

+ (MBESafeArray)createNormalizeSphereIndicesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
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

		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:0 meridianIndex:i   parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:1 meridianIndex:i   parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:1 meridianIndex:i+1 parallels:parallels meridians:meridians];

		MBESafeArrayFree(offsetArr);

		indicesIndex += 3;
	}

	// calculate triangles near bottom pole
	for (int i=0; i<meridians; i++) {
		MBESafeArray offsetArr = MBESafeArrayCreateOffsetArray(indicesArr, indicesIndex);
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:parallels+1 meridianIndex:i   parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:parallels   meridianIndex:i+1 parallels:parallels meridians:meridians];
		*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:parallels   meridianIndex:i   parallels:parallels meridians:meridians];
		MBESafeArrayFree(offsetArr);

		indicesIndex += 3;
	}

	// Next calculate triangles for rows
	for (int p=1; p<parallels; p++) {
		for (int m=0; m<meridians; m++) {
			MBESafeArray offsetArr = MBESafeArrayCreateOffsetArray(indicesArr, indicesIndex);
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:p meridianIndex:m+1 parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:p meridianIndex:m parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m parallels:parallels meridians:meridians];
			MBESafeArrayFree(offsetArr);

			indicesIndex += 3;

			offsetArr = MBESafeArrayCreateOffsetArray(indicesArr, indicesIndex);
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 0)) = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 1)) = [self indexForSpherePointAtParallelIndex:p+1 meridianIndex:m+1 parallels:parallels meridians:meridians];
			*((MBEIndex *)MBESafeArrayGetPointer(offsetArr, 2)) = [self indexForSpherePointAtParallelIndex:p meridianIndex:m+1 parallels:parallels meridians:meridians];
			MBESafeArrayFree(offsetArr);

			indicesIndex += 3;
		}
	}

	return indicesArr;
}

+ (NSUInteger)indexForSpherePointAtParallelIndex:(NSUInteger)parallelIndex meridianIndex:(NSUInteger)meridianIndex parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians
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

@end
