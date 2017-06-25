//
//  MBECubePointLight.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/17/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBEObject.h"
#import "MBEPointLightSource.h"

@interface MBECubePointLight : NSObject <MBEPointLightSource, MBERenderable>

- (instancetype)initWithDevice:(id<MTLDevice>)device color:(vector_float4)color strength:(float)strength K:(float)K L:(float)L Q:(float)Q;

@end
