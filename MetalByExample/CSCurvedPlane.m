//
//  CSCurvedPlane.m
//  CurvedSurfaceMetal iOS
//
//  Created by Vivek Seth on 8/5/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "CSCurvedPlane.h"
#import "MBEShaderStructs.h"
#import <CoreGraphics/CoreGraphics.h>

@interface CSCurvedPlane ()

@property id<MTLBuffer> vertexBuffer;

@end

@implementation CSCurvedPlane

@synthesize device;
@synthesize x, y, z, scale;

- (instancetype)init
{
	self = [super init];

	_uSegments = 30;
	_vSegments = 10;

//	_uRange = (vector_float2){-M_PI_4, M_PI_4};
//	_vRange = (vector_float2){0, 2};

//	_fx = ^CGFloat(CGFloat u, CGFloat v) {
//		return sin(u);
//	};
//
//	_fy = ^CGFloat(CGFloat u, CGFloat v) {
//		return v;
//	};
//
//	_fz = ^CGFloat(CGFloat u, CGFloat v) {
//		return 10 - cos(u);
//	};

	_uRange = (vector_float2){-100, 100};
	_vRange = (vector_float2){0, 100};
	_fx = ^CGFloat(CGFloat u, CGFloat v) {
		return u;
	};

	_fy = ^CGFloat(CGFloat u, CGFloat v) {
		return v;
	};

	_fz = ^CGFloat(CGFloat u, CGFloat v) {
		return 3;
	};


	CGFloat numTriangles = _uSegments * _vSegments * 2;

	// Pass this in from the constructur.
	id<MTLDevice> device = MTLCreateSystemDefaultDevice();

	size_t bufferSize = (numTriangles * 3 * sizeof(MBEVertexIn));
	MBEVertexIn *buffer = malloc(bufferSize);

	NSInteger numPoints = [self populateBuffer:buffer];
	_numPoints = numPoints;

	assert(numPoints == (numTriangles * 3));

	self.vertexBuffer = [device newBufferWithBytes:buffer length:bufferSize options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];
	free(buffer);

	return self;
}

- (NSUInteger)populateBuffer:(MBEVertexIn *)buffer
{
	NSUInteger bufferIndex = 0;
	for (NSInteger u=0; u<_uSegments; u++) {
		CGFloat uStep = (self.uRange.y - self.uRange.x) / (CGFloat)_uSegments;
		CGFloat uLow = u * uStep + self.uRange.x;
		CGFloat uHigh = u * (uStep + 1) + self.uRange.x;

		for (NSInteger v=0; v<_vSegments; v++) {
			CGFloat vStep = (self.vRange.y - self.vRange.x) / (CGFloat)_vSegments;
			CGFloat vLow = v * vStep + self.vRange.x;
			CGFloat vHigh = v * (vStep + 1) + self.vRange.x;

			MBEVertexIn p1 = [self vertFromU:uLow V:vLow];
			MBEVertexIn p2 = [self vertFromU:uLow V:vHigh];
			MBEVertexIn p3 = [self vertFromU:uHigh V:vHigh];
			MBEVertexIn p4 = [self vertFromU:uHigh V:vLow];

			// Triangle 1
			buffer[bufferIndex++] = p1;
			buffer[bufferIndex++] = p2;
			buffer[bufferIndex++] = p3;

			// Triangle 2
			buffer[bufferIndex++] = p2;
			buffer[bufferIndex++] = p3;
			buffer[bufferIndex++] = p4;
		}
	}

	return bufferIndex;
}

- (MBEVertexIn)vertFromU:(CGFloat)u V:(CGFloat)v
{
	MBEVertexIn vert;
	vert.position = [self posFromU:u V:v];
	vert.texCoord = [self texCoordFromU:u V:v];
	return vert;
}

- (vector_float4)posFromU:(CGFloat)u V:(CGFloat)v
{
	return (vector_float4){
		_fx(u, v),
		_fy(u, v),
		_fz(u, v),
		1,
	};
}

- (vector_float2)texCoordFromU:(CGFloat)u V:(CGFloat)v
{
	CGFloat tu = (u - _uRange.x) / (_uRange.y - _uRange.x);
	CGFloat tv = (v - _vRange.x) / (_vRange.y - _vRange.x);
	return (vector_float2){tu, tv};
}

#pragma mark <MBEObject>

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder
{
	// [renderCommandEncoder setVertexBuffer:self.vertexObjectUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
	//[renderCommandEncoder setFragmentBuffer:self.fragmentMaterialUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numPoints];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView {

}

@end



















