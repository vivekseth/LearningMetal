//
//  MultipleLighting.metal
//  MetalByExample
//
//  Created by Vivek Seth on 6/16/17.
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

struct VertexSceneUniforms
{
	float4x4 worldToView;
	float4x4 viewToProjection;
};

struct VertexObjectUniforms
{
	float4x4 modelToWorld;
	float3x3 normalMatrix;
};

struct FragmentMaterialUniforms
{
	float4 objectColor;
	float ambientStrength;
	float diffuseStrength;
	float specularStrength;
	float specularFactor;
};

#define MBE_MAX_POINT_LIGHTS 10

struct FragmentPointLight
{
	float4 position;
	float4 color;
	float strength;
	float K;
	float L;
	float Q;
};

struct FragmentLightUniforms
{
	float4 viewPosition;
	int8_t numPointLights;
	FragmentPointLight pointLights[MBE_MAX_POINT_LIGHTS];
};

float4 lightForPointLight(FragmentPointLight pointLight,
						  FragmentMaterialUniforms materialUniforms,
						  float4 viewPosition,
						  VertexOut vert);





vertex VertexOut multiple_lights_vertex_projection(device VertexIn *vertices [[buffer(0)]],
										 constant VertexSceneUniforms &sceneUniforms [[buffer(1)]],
										 constant VertexObjectUniforms &objectUniforms [[buffer(2)]],
										 uint vid [[vertex_id]])
{
	VertexIn in = vertices[vid];

	VertexOut out;
	out.fragPos = objectUniforms.modelToWorld * in.position;
	out.position = sceneUniforms.viewToProjection * sceneUniforms.worldToView * objectUniforms.modelToWorld * in.position;
	out.normal = objectUniforms.normalMatrix * in.normal;
	out.color = in.color;
	return out;
}

float4 lightForPointLight(FragmentPointLight pointLight,
						  FragmentMaterialUniforms materialUniforms,
						  float4 viewPosition,
						  VertexOut vert)
{
	// ambient
	float3 ambient = materialUniforms.ambientStrength * float3(pointLight.color);

	// diffuse
	float3 norm = normalize(vert.normal);
	float3 lightDir = float3(normalize(pointLight.position - vert.fragPos));
	// HACK! not sure why i need this.
	lightDir.z = -1 * lightDir.z;
	float diff = max(dot(norm, lightDir), 0.0);
	float3 diffuse = materialUniforms.diffuseStrength * diff * float3(pointLight.color);

	// specular
	float3 viewDirection = float3(normalize(viewPosition - vert.fragPos));
	float3 reflectDirection = reflect(-lightDir, norm);
	float spec = pow(max(dot(viewDirection, reflectDirection), 0.0), materialUniforms.specularFactor);
	float3 specular = float3(materialUniforms.specularStrength * spec * pointLight.color);

	float4 light = float4(diffuse + ambient + specular, 1.0);
	return light;
}

fragment float4 multiple_lights_fragment(VertexOut vertexIn [[stage_in]],
								  constant FragmentMaterialUniforms &materialUniforms [[buffer(0)]],
								  constant FragmentLightUniforms &lightUniforms [[buffer(1)]])
{
	float4 light = float4(0);

	// Accumulate light from pointLights. 
	for (int i=0; i<lightUniforms.numPointLights; i++) {
		FragmentPointLight pointLight = lightUniforms.pointLights[i];
		light += lightForPointLight(pointLight, materialUniforms, lightUniforms.viewPosition, vertexIn);
	}

	return light * materialUniforms.objectColor;
}


