//
//  Shaders.metal
//  MetalByExample
//
//  Created by Vivek Seth on 6/7/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
	float4 position [[position]];
	float4 color;
};

struct VertexOut
{
	float4 position [[position]];
	float4 color;
	float3 normal;
	float pointSize [[point_size]];
};

struct Uniforms
{
	float4x4 modelViewProjectionMatrix;
};


vertex VertexOut vertex_project(device Vertex *vertices [[buffer(0)]],
							 constant Uniforms *uniforms [[buffer(1)]],
							 uint vid [[vertex_id]])
{
	float3 normal = vertices[vid].position.xyz;

	VertexOut vertexOut;
	vertexOut.position = uniforms->modelViewProjectionMatrix * vertices[vid].position;
	vertexOut.color = vertices[vid].color;
	vertexOut.normal = normal;
	vertexOut.pointSize = 30.0;

	return vertexOut;
}

fragment float4 fragment_flatcolor(VertexOut vertexIn [[stage_in]],
								   float2 pointCoord [[point_coord]])
{
	float2 recenteredPointCoord = pointCoord - float2(0.5, 0.5);


	float radius = sqrt(recenteredPointCoord.x * recenteredPointCoord.x + recenteredPointCoord.y * recenteredPointCoord.y);

	float alpha = pow(2, -30 * radius);

	float3 color = float3(0, 0, 0);
	return float4(color, alpha);
}
