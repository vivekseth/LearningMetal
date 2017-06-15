//
//  MBECube.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "MBEObject.h"

@interface MBECube : NSObject<MBEObject>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end
