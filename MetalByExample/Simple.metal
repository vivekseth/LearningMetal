//
//  File.metal
//  MetalByExample
//
//  Created by Vivek Seth on 6/17/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#include <metal_stdlib>
#import "Utilities/MBEShaderStructs.h"

using namespace metal;

struct MBESimpleVertexOut
{
	float4 position [[position]];
	float4 color;
};

vertex MBESimpleVertexOut simple_vertex_projection(constant MBESceneUniforms &sceneUniforms [[buffer(0)]],
												   constant MBEVertexObjectUniforms &objectUniforms [[buffer(1)]],
												   device MBEVertexIn *vertices [[buffer(2)]],
												   uint vid [[vertex_id]])
{
	MBEVertexIn in = vertices[vid];

	MBESimpleVertexOut out;
	out.position = sceneUniforms.viewToProjection * sceneUniforms.worldToView * objectUniforms.modelToWorld * in.position;
	out.color = in.color;
	return out;
}

fragment float4 simple_fragment(constant MBEFragmentPointLight &pointLight [[buffer(0)]],
								MBESimpleVertexOut vertexIn [[stage_in]])
{
	return pointLight.color;
}

