//
//  MBESphereUtility.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/25/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBEShaderStructs.h"
#import "MBESafeArray.h"

@interface MBESphereUtility : NSObject

+ (void)printSphereDotObjWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians;

+ (MBESafeArray)createNormalizeSphereVerticesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians;

+ (void)generateVerticesForRingWithRadius:(CGFloat)radius zOffset:(CGFloat)zOffset numDivisions:(NSUInteger)numDivisions array:(MBESafeArray)array;

+ (MBESafeArray)createNormalizeSphereIndicesWithParallels:(NSUInteger)parallels meridians:(NSUInteger)meridians;

+ (NSUInteger)indexForSpherePointAtParallelIndex:(NSUInteger)parallelIndex meridianIndex:(NSUInteger)meridianIndex parallels:(NSUInteger)parallels meridians:(NSUInteger)meridians;

@end
