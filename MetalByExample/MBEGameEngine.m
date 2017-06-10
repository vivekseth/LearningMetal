//
//  MBEGameEngine.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBEGameEngine.h"
#import "MBERenderer.h"
#import "MBECube.h"

@interface MBEGameEngine ()

@property (readonly) id<MTLDevice> device;
@property (nonatomic, strong) MBERenderer *renderer;

@property (assign) float time;
@property (nonatomic, strong) MBECube *cube;

@end

@implementation MBEGameEngine

- (instancetype)initWithSize:(CGSize)size
{
	self = [super init];

	_device = MTLCreateSystemDefaultDevice();
	_renderer = [[MBERenderer alloc] initWithSize:size device:self.device];
	_cube = [[MBECube alloc] initWithDevice:self.device];

	return self;
}

#pragma mark <MTKViewDelegate>

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
	[self.renderer drawableSizeWillChange:size];
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
	[self.renderer blockUntilNextRender];

	float prevTime = self.time;
	self.time = CACurrentMediaTime();
	float duration = self.time - prevTime;

	[self.cube updateWithTime:self.time duration:duration viewProjectionMatrix:self.renderer.viewProjectionMatrix];

	[self.renderer renderObjects:@[self.cube] MTKView:view];
}

#pragma mark - Input Handlers

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)keyUp:(NSEvent*)event
{

}

- (void)keyDown:(NSEvent*)event
{
	// W
	if (event.keyCode == 13) {
		// self.cube.y += 0.1;
	}

	// A
	if (event.keyCode == 0) {
		// self.cube.x -= 0.1;
	}

	// S
	if (event.keyCode == 1) {
		// self.cube.y -= 0.1;
	}

	// D
	if (event.keyCode == 2) {
		// self.cube.x += 0.1;
	}
}

@end
