//
//  MBEGameEngine.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBEGameEngine.h"
#import "MBERenderer.h"
#import "MBEObject.h"
#import "MBECube.h"
#import "MBESphere.h"

@interface MBEGameEngine ()

@property (readonly) id<MTLDevice> device;
@property (nonatomic, strong) MBERenderer *renderer;

@property (assign) float time;

@property (nonatomic, strong) NSMutableArray <id<MBEObject>> *objects;

@end

@implementation MBEGameEngine

- (instancetype)initWithSize:(CGSize)size
{
	self = [super init];

	_device = MTLCreateSystemDefaultDevice();
	_renderer = [[MBERenderer alloc] initWithSize:size device:self.device];
	_objects = [NSMutableArray array];

//	int N = 9;
//	int low = -1*N/2;
//	int high = N/2+1;
//
//	for (int i=low; i<high; i++) {
//		for (int j=low; j<high; j++) {
//			for (int k=low; k<high; k++) {
//
//				MBECube *cube = [[MBECube alloc] initWithDevice:self.device];
//				cube.x = i * 1.3;
//				cube.y = j * 1.3;
//				cube.z = k * 1.3;
//
//				[self.objects addObject:cube];
//			}
//		}
//	}

	MBESphere *sphere = [[MBESphere alloc] initWithDevice:self.device parallels:20 meridians:20];
	[self.objects addObject:sphere];

	return self;
}

#pragma mark <MTKViewDelegate>

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
	[self.renderer drawableSizeWillChange:size];
}

/**
TODO
 1. Objects should move with velocity
 2. Objects should move with accelleration (there should be a concept of gravity or force source)
 3. Select object by clicking on it
 4. Outline object using stencil
 5. Create another primitive shape class (sphere?)
 6. Create 3d rectangle with dynamic height
 6. Create scene of cubes and allow user to navigate through scene (specify scene using DSL grid)
 7. Enable jumping (will require rudimentally collision detection)

 */

- (void)drawInMTKView:(nonnull MTKView *)view
{
	[self.renderer blockUntilNextRender];

	float prevTime = self.time;
	self.time = CACurrentMediaTime();
	float duration = self.time - prevTime;

	// 1. Handle User Input
	// TODO

	// 2. Update objects in Scene
	for (id<MBEObject> obj in self.objects) {
		[obj updateWithTime:self.time duration:duration viewProjectionMatrix:self.renderer.viewProjectionMatrix];
	}

	// 3. Render objects to view
	[self.renderer renderObjects:self.objects MTKView:view];
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
