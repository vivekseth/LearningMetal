//
//  Lighting.metal
//  MetalByExample
//
//  Created by Vivek Seth on 6/14/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
	float4 position [[position]];
	float4 color;
	float3 normal;
};

struct VertexOut
{
	float4 position [[position]];
	float4 color;
	float3 normal;
	float4 fragPos;
};

struct VertexUniforms
{
	float4x4 modelToWorld;
	float4x4 worldToView;
	float4x4 viewToProjection;
	float3x3 normalMatrix;
};

struct FragmentUniforms
{
	float4 viewPosition; // camera position
	float4 objectColor;
	float4 lightPosition;
	float4 lightColor;
};

vertex VertexOut lighting_vertex_project(device VertexIn *vertices [[buffer(0)]],
										 constant VertexUniforms *uniforms [[buffer(1)]],
										 uint vid [[vertex_id]])
{
	VertexIn in = vertices[vid];

	VertexOut out;
	out.fragPos = uniforms->modelToWorld * in.position;
	out.position = uniforms->viewToProjection * uniforms->worldToView * uniforms->modelToWorld * in.position;
	out.normal = uniforms->normalMatrix * in.normal;
	out.color = in.color;
	return out;
}

fragment float4 lighting_fragment(VertexOut vertexIn [[stage_in]], constant FragmentUniforms *uniforms [[buffer(0)]])
{

// return vertexIn.position;

	// ambient
	float ambientStrength = 0.3;
	float3 ambient = ambientStrength * float3(uniforms->lightColor);

	// diffuse
	float3 norm = normalize(vertexIn.normal);
	float3 lightDir = float3(normalize(uniforms->lightPosition - vertexIn.fragPos));

	// HACK! not sure why i need this.
	lightDir.z = -1 * lightDir.z;

	float diff = max(dot(norm, lightDir), 0.0);
	float3 diffuse = diff * float3(uniforms->lightColor);

	// specular
	float specularStrength = 0.5;
	float3 viewDirection = float3(normalize(uniforms->viewPosition - vertexIn.fragPos));
	float3 reflectDirection = reflect(-lightDir, norm);
	float spec = pow(max(dot(viewDirection, reflectDirection), 0.0), 32);
	float3 specular = float3(specularStrength * spec * uniforms->lightColor);

	float4 light = float4(diffuse + ambient + specular, 1.0);

	return light * uniforms->objectColor;
}



