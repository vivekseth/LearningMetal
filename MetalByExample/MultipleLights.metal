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

/// Declarations

struct MBEVertexOut
{
	float4 position [[position]];
	float4 color;
	float3 normal;
	float4 worldSpacePosition;
	float4 viewSpacePosition;
};

float4 lightForPointLight(MBESceneUniforms sceneUniforms,
						  MBEFragmentPointLight pointLight,
						  MBEFragmentMaterialUniforms materialUniforms,
						  float4 viewPosition,
						  MBEVertexOut vert);

float4 lightForPointLight2(MBESceneUniforms sceneUniforms,
						   MBEFragmentPointLight pointLight,
						   MBEFragmentMaterialUniforms materialUniforms,
						   float4 viewPosition,
						   MBEVertexOut vert);

/// Definitions

vertex MBEVertexOut multiple_lights_vertex_projection(constant MBESceneUniforms &sceneUniforms [[buffer(MBEVertexShaderIndexSceneUniforms)]],
													  constant MBEVertexObjectUniforms &objectUniforms [[buffer(MBEVertexShaderIndexObjectUniforms)]],
													  device MBEVertexIn *vertices [[buffer(MBEVertexShaderIndexVertices)]],
													  uint vid [[vertex_id]])
{
	MBEVertexIn in = vertices[vid];

	MBEVertexOut out;
	out.worldSpacePosition = objectUniforms.modelToWorld * in.position;
	out.viewSpacePosition = sceneUniforms.worldToView * objectUniforms.modelToWorld * in.position;
	out.position = sceneUniforms.viewToProjection * sceneUniforms.worldToView * objectUniforms.modelToWorld * in.position;
	out.normal = normalize(/*objectUniforms.normalMatrix * */ in.normal);
	out.color = in.color;
	return out;
}

fragment float4 multiple_lights_fragment(constant MBESceneUniforms &sceneUniforms [[buffer(MBEFragmentShaderIndexSceneUniforms)]],
										 constant MBEFragmentLightUniforms &lightUniforms [[buffer(MBEFragmentShaderIndexLightUniforms)]],
										 constant MBEFragmentMaterialUniforms &materialUniforms [[buffer(MBEFragmentShaderIndexMaterialUniforms)]],
										 MBEVertexOut vertexIn [[stage_in]])
{
	return float4(((vertexIn.normal).z + 1.0) * 0.5);
	return float4((vertexIn.normal + 1.0) * 0.5, 1);

	float4 light = float4(0);

	// Accumulate light from pointLights. 
	for (int i=0; i<lightUniforms.numPointLights; i++) {
		MBEFragmentPointLight pointLight = lightUniforms.pointLights[i];
		light += lightForPointLight2(sceneUniforms, pointLight, materialUniforms, lightUniforms.viewPosition, vertexIn);
	}

	return light * materialUniforms.objectColor;
}

/// Utility

float4 lightForPointLight2(MBESceneUniforms sceneUniforms,
						  MBEFragmentPointLight pointLight,
						  MBEFragmentMaterialUniforms materialUniforms,
						  float4 viewPosition,
						  MBEVertexOut vert)
{
	float4 worldSpaceLightPosition = pointLight.position;
	float4 worldSpaceFragPosition = vert.worldSpacePosition;
	float4 worldSpaceRelativeLightPosition = worldSpaceLightPosition - worldSpaceFragPosition;
	float4 viewSpaceRelaiveLightPosition = sceneUniforms.worldToView * worldSpaceRelativeLightPosition;
	float angle = dot(normalize(vert.normal), normalize(viewSpaceRelaiveLightPosition.xyz));
	float intensity = max(0.0, angle);
	return intensity * float4(1.0);
}

float4 lightForPointLight(MBESceneUniforms sceneUniforms,
						  MBEFragmentPointLight pointLight,
						  MBEFragmentMaterialUniforms materialUniforms,
						  float4 viewPosition,
						  MBEVertexOut vert)
{
	float4 viewSpaceLightPosition = sceneUniforms.worldToView * pointLight.position;

	float d = length(viewSpaceLightPosition - vert.viewSpacePosition);
	float attenuation = 1.0 / (pointLight.K + pointLight.L * d + pointLight.Q * (d * d));

	// ambient
	float3 ambient = materialUniforms.ambientStrength * float3(pointLight.color);

	// diffuse
	float3 norm = normalize(vert.normal);
	float3 lightDir = float3(normalize(viewSpaceLightPosition - vert.viewSpacePosition));
	// HACK! not sure why i need this.
	// lightDir.z = -1 * lightDir.z;
	float diff = max(dot(norm, lightDir), 0.0);
	float3 diffuse = materialUniforms.diffuseStrength * diff * float3(pointLight.color);

	// specular
	float3 viewDirection = float3(normalize(viewPosition - vert.viewSpacePosition));
	float3 reflectDirection = reflect(-lightDir, norm);
	float spec = pow(max(dot(viewDirection, reflectDirection), 0.0), materialUniforms.specularFactor);
	float3 specular = float3(materialUniforms.specularStrength * spec * pointLight.color);

	float4 light = attenuation * pointLight.strength * float4(diffuse + ambient + specular, 1.0);
	return light;
}
