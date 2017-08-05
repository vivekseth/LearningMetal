//
//  CSCurvedPlane.h
//  CurvedSurfaceMetal iOS
//
//  Created by Vivek Seth on 8/5/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <simd/simd.h>
#import <MetalKit/MetalKit.h>

@interface CSCurvedPlane : NSObject

@property (nonatomic) NSInteger uSegments;
@property (nonatomic) NSInteger vSegments;
@property (nonatomic) vector_float2 uRange;
@property (nonatomic) vector_float2 vRange;
@property (nonatomic, readonly) NSInteger numPoints;

@property (nonatomic) CGFloat (^fx)(CGFloat, CGFloat);
@property (nonatomic) CGFloat (^fy)(CGFloat, CGFloat);
@property (nonatomic) CGFloat (^fz)(CGFloat, CGFloat);

@property id<MTLBuffer> vertexBuffer;

@end
