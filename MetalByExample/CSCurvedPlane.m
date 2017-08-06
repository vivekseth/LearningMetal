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
//#import "MBETextureLoader.h"

@interface CSCurvedPlane ()

@property id<MTLBuffer> vertexBuffer;

@property id<MTLBuffer> vertexObjectUniformsBuffer;
@property id<MTLBuffer> fragmentMaterialUniformsBuffer;

@property (strong) id<MTLSamplerState> samplerState;
@property (strong) id<MTLTexture> diffuseTexture;

@end

@implementation CSCurvedPlane

@synthesize device;
@synthesize x, y, z, scale;

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
	self = [super init];

	self.device = device;

	CGFloat radius = 5;
	_uSegments = 30;
	_vSegments = 10;

	CGFloat arcLength = (M_PI_2 / (2 * M_PI)) * (radius * 2) * M_PI;

	_uRange = (vector_float2){-3, 3};
	_vRange = (vector_float2){0, arcLength};

	_fx = ^CGFloat(CGFloat u, CGFloat v) {
		return u; // radius * sin(u);
	};

	_fy = ^CGFloat(CGFloat u, CGFloat v) {
		return v;
	};

	_fz = ^CGFloat(CGFloat u, CGFloat v) {
		return 18 - radius * cos(u) + 0.2 * sin(0.2 * u);
	};

	CGFloat numTriangles = _uSegments * _vSegments * 2;

	size_t bufferSize = (numTriangles * 3 * sizeof(MBEVertexIn));
	MBEVertexIn *buffer = malloc(bufferSize);

	NSInteger numPoints = [self populateBuffer:buffer];
	_numPoints = numPoints;

	self.vertexBuffer = [device newBufferWithBytes:buffer length:bufferSize options:MTLResourceOptionCPUCacheModeDefault];
	[self.vertexBuffer setLabel:@"Vertices"];
	free(buffer);

	MBEVertexObjectUniforms vertexObjectUniforms;
	vertexObjectUniforms.modelToWorld = matrix_float4x4_uniform_scale(1.0);

	self.vertexObjectUniformsBuffer = [self.device newBufferWithBytes:&vertexObjectUniforms length:sizeof(vertexObjectUniforms) options:MTLResourceOptionCPUCacheModeDefault];
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


	// create sampler state
	MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
	samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
	samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
	samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
	samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
	samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
	_samplerState = [self.device newSamplerStateWithDescriptor:samplerDesc];

	NSImage *checkerboardImage = [NSImage imageNamed:@"checkerboard"];
	MTKTextureLoader *textureLoader2 = [[MTKTextureLoader alloc] initWithDevice:self.device];
	CGImageRef cgCheckerboardImage = [checkerboardImage CGImageForProposedRect:nil context:nil hints:nil];
	NSError *error = nil;
	NSDictionary *options = @{
							  MTKTextureLoaderOptionGenerateMipmaps: @(YES),
							  MTKTextureLoaderOptionSRGB: @(NO)
							  };
	_diffuseTexture = [textureLoader2 newTextureWithCGImage:cgCheckerboardImage options:options error:&error];
	if (!_diffuseTexture) {
		NSLog(@"%@", error);
	}
	
	return self;
}

- (NSUInteger)populateBuffer:(MBEVertexIn *)buffer
{
	NSUInteger bufferIndex = 0;
	for (NSInteger u=0; u<_uSegments; u++) {
		CGFloat uStep = (self.uRange.y - self.uRange.x) / (CGFloat)_uSegments;
		CGFloat uLow = u * uStep + self.uRange.x;
		CGFloat uHigh = (u + 1) * uStep + self.uRange.x;

		for (NSInteger v=0; v<_vSegments; v++) {
			CGFloat vStep = (self.vRange.y - self.vRange.x) / (CGFloat)_vSegments;
			CGFloat vLow = v * vStep + self.vRange.x;
			CGFloat vHigh = (v + 1) * vStep + self.vRange.x;

			MBEVertexIn p1 = [self vertFromU:uLow V:vLow];
			MBEVertexIn p2 = [self vertFromU:uLow V:vHigh];
			MBEVertexIn p3 = [self vertFromU:uHigh V:vHigh];
			MBEVertexIn p4 = [self vertFromU:uHigh V:vLow];

			// Triangle 1
			buffer[bufferIndex++] = p1;
			buffer[bufferIndex++] = p2;
			buffer[bufferIndex++] = p3;

			// Triangle 2
			buffer[bufferIndex++] = p3;
			buffer[bufferIndex++] = p4;
			buffer[bufferIndex++] = p1;
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
	return (vector_float2){1 - tu, 1 - tv};
}

#pragma mark <MBEObject>

- (void)encodeRenderCommand:(id<MTLRenderCommandEncoder>)renderCommandEncoder
{
	[renderCommandEncoder setVertexBuffer:self.vertexObjectUniformsBuffer offset:0 atIndex:1];
	[renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
	[renderCommandEncoder setFragmentBuffer:self.fragmentMaterialUniformsBuffer offset:0 atIndex:1];

	[renderCommandEncoder setFragmentTexture:self.diffuseTexture atIndex:0];
	[renderCommandEncoder setFragmentSamplerState:self.samplerState atIndex:0];

	[renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numPoints];
}

- (void)updateWithTime:(CGFloat)time duration:(CGFloat)duration worldToView:(matrix_float4x4)worldToView {

}

@end



















