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

	return vertexOut;
}

fragment float4 fragment_flatcolor(VertexOut vertexIn [[stage_in]])
{
	float3 lightDirection = float3(1, 1, 1);
	float3 lightDiffuseColor = float3(1, 1, 1);
	float3 materialDiffuseColor = float3(1, 0, 0);

	float3 normal = normalize(vertexIn.normal);
	float diffuseIntensity = saturate(dot(normal, lightDirection));
	float3 diffuseTerm = lightDiffuseColor * materialDiffuseColor * diffuseIntensity;

	return float4(diffuseTerm + 0.5 * materialDiffuseColor, 1);
}
