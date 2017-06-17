//
//  MBERenderer.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <Cocoa/Cocoa.h>
#import "MBEObject.h"
#import "MBEPointLightSource.h"

@interface MBERenderer : NSObject

@property (nonatomic, readonly) matrix_float4x4 viewToProjectionMatrix;

- (instancetype)initWithSize:(CGSize)size device:(id<MTLDevice>)device;

- (void)drawableSizeWillChange:(CGSize)size;

- (void)blockUntilNextRender;

- (void)renderObjects:(NSArray <id<MBEObject>> *)objects
		 lightSources:(NSArray <id<MBEPointLightSource>> *)lightSources
		 viewPosition:(vector_float4)viewPosition
			  MTKView:(MTKView *)view;

@end
