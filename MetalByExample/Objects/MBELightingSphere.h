//
//  MBESphere.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/10/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "MBEObject.h"

typedef struct {
    vector_float4 objectColor;
    float ambientStrength;
    float diffuseStrength;
    float specularStrength;
    float specularFactor;
} MBELightingSphereFragmentMaterialUniforms;

@interface MBELightingSphere : NSObject<MBEObject>

@property (nonatomic) MBELightingSphereFragmentMaterialUniforms material;

- (instancetype) initWithDevice:(id<MTLDevice>)device parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians;

@end
