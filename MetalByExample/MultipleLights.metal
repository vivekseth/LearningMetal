//
//  MultipleLighting.metal
//  MetalByExample
//
//  Created by Vivek Seth on 6/16/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#include <metal_stdlib>

#import "Utilities/MBEShaderStructs.h"

using namespace metal;

struct MBEVertexOut
{
	float4 position [[position]];
	float4 color;
	float3 normal;
	float4 fragPos;
};

float4 lightForPointLight(MBEFragmentPointLight pointLight,
						  MBEFragmentMaterialUniforms materialUniforms,
						  float4 viewPosition,
						  MBEVertexOut vert);





vertex MBEVertexOut multiple_lights_vertex_projection(constant MBEVertexSceneUniforms &sceneUniforms [[buffer(0)]],
													  constant MBEVertexObjectUniforms &objectUniforms [[buffer(1)]],
													  device MBEVertexIn *vertices [[buffer(2)]],
													  uint vid [[vertex_id]])
{
	MBEVertexIn in = vertices[vid];

	MBEVertexOut out;
	out.fragPos = objectUniforms.modelToWorld * in.position;
	out.position = sceneUniforms.viewToProjection * sceneUniforms.worldToView * objectUniforms.modelToWorld * in.position;
	out.normal = objectUniforms.normalMatrix * in.normal;
	out.color = in.color;
	return out;
}

float4 lightForPointLight(MBEFragmentPointLight pointLight,
						  MBEFragmentMaterialUniforms materialUniforms,
						  float4 viewPosition,
						  MBEVertexOut vert)
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

fragment float4 multiple_lights_fragment(constant MBEFragmentLightUniforms &lightUniforms [[buffer(0)]],
										 constant MBEFragmentMaterialUniforms &materialUniforms [[buffer(1)]],
										 MBEVertexOut vertexIn [[stage_in]])
{
	float4 light = float4(0);

	// Accumulate light from pointLights. 
	for (int i=0; i<lightUniforms.numPointLights; i++) {
		MBEFragmentPointLight pointLight = lightUniforms.pointLights[i];
		light += lightForPointLight(pointLight, materialUniforms, lightUniforms.viewPosition, vertexIn);
	}

	return light * materialUniforms.objectColor;
}


