//
//  MBEShaderStructs.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/16/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <simd/simd.h>

typedef enum MBEVertexShaderIndex {
	MBEVertexShaderIndexSceneUniforms = 0,
	MBEVertexShaderIndexObjectUniforms = 1,
	MBEVertexShaderIndexVertices = 2,
} MBEVertexShaderIndex;

typedef enum MBEFragmentShaderIndex {
	MBEFragmentShaderIndexSceneUniforms = 0,
	MBEFragmentShaderIndexLightUniforms = 1,
	MBEFragmentShaderIndexMaterialUniforms = 2,
} MBEFragmentShaderIndex;

typedef struct {
	vector_float4 position;
	vector_float4 color;
	vector_float3 normal;
} MBEVertexIn;

typedef struct {
	matrix_float4x4 modelToWorld;
	matrix_float3x3 normalMatrix;
} MBEVertexObjectUniforms;

typedef struct {
	matrix_float4x4 worldToView;
	matrix_float4x4 viewToProjection;
} MBESceneUniforms;

typedef struct {
	vector_float4 objectColor;
	float ambientStrength;
	float diffuseStrength;
	float specularStrength;
	float specularFactor;
} MBEFragmentMaterialUniforms;

//typedef struct {
//	vector_float4 direction;
//	vector_float4 color;
//	float strength;
//} MBEFragmentDirectionalLight;

#define MBE_MAX_POINT_LIGHTS 10

typedef struct {
	vector_float4 position;
	vector_float4 color;
	float strength;

	float K;
	float L;
	float Q;
} MBEFragmentPointLight;

typedef struct {
	vector_float4 viewPosition;

	// MBEFragmentDirectionalLight directionalLight;

	int numPointLights;
	MBEFragmentPointLight pointLights[MBE_MAX_POINT_LIGHTS];
} MBEFragmentLightUniforms;

