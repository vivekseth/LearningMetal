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
#import "MBEKeyboardUtilities.h"
#import "MBEPointLightSource.h"
#import "MBECubePointLight.h"
#import "MBECamera.h"

@interface MBEGameEngine ()

@property (readonly) id<MTLDevice> device;
@property (nonatomic, strong) MBERenderer *renderer;

// Camera
// @property (nonatomic) float rotY;
@property (nonatomic) vector_float4 position;

@property (assign) float time;
@property (nonatomic) matrix_float4x4 worldToViewMatrix;

@property (nonatomic, strong) NSMutableArray <id<MBEPointLightSource>> *lightSources;
@property (nonatomic, strong) NSMutableArray <id<MBEObject>> *objects;

@property (nonatomic, strong) NSMutableSet *pressedKeys;
@property (nonatomic, strong) NSSet *modifierFlags;
@property (nonatomic, strong) NSMutableArray *keyEvents;

@end

@implementation MBEGameEngine

- (instancetype)initWithSize:(CGSize)size
{
	self = [super init];

	_pressedKeys = [NSMutableSet set];
	_keyEvents = [NSMutableArray array];

	_device = MTLCreateSystemDefaultDevice();
	_renderer = [[MBERenderer alloc] initWithSize:size device:self.device];
	_objects = [NSMutableArray array];
	_lightSources = [NSMutableArray array];

	// Create scene
	[self createScene];

	[self updateWorldToViewMatrix];

	return self;
}

- (void)createScene
{
	const vector_float4 cameraTranslation = {5, 5, 5, 1};
	self.position = cameraTranslation;

	_objects = [NSMutableArray array];

	int N = 24;
	int low = -1*N/2;
	int high = N/2+1;

	for (int i=low; i<high; i++) {
		for (int j=low; j<high; j++) {
			MBESphere *sphere = [[MBESphere alloc] initWithDevice:self.device parallels:20 meridians:20];
			sphere.x = i*2;
			sphere.y = 0.1 * i * j;
			sphere.z = j*2;
			[self.objects addObject:sphere];
		}
	}

	float radius = 10;
	int numLights = 4;
	for (int i=0; i<numLights; i++) {

		float angle = 2 * M_PI * ((float)i/(float)numLights);
		MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
		light.x = radius*cos(angle);
		light.y = 15;
		light.z = radius*sin(angle);
		[self.lightSources addObject:light];

		NSLog(@"light @ (%f, %f)", (float)light.x, (float)light.z);

	}
}

- (void)createSingleSphere
{
	const vector_float4 cameraTranslation = {0, 0, -8, 1};
	self.position = cameraTranslation;

	_objects = [NSMutableArray array];
	MBESphere *sphere = [[MBESphere alloc] initWithDevice:self.device parallels:20 meridians:20];
	[self.objects addObject:sphere];
}

- (void)mutliPointLightDemo
{
	const vector_float4 cameraTranslation = {0, 0, -8, 1};
	self.position = cameraTranslation;

	MBECubePointLight *redLight = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
	redLight.x = 5;
	redLight.y = 5;
	redLight.z = 0;
	[self.lightSources addObject:redLight];

	MBECubePointLight *blueLight = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
	blueLight.x = -5;
	blueLight.y = -5;
	blueLight.z = 0;
	[self.lightSources addObject:blueLight];

	MBECubePointLight *greenLight = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
	greenLight.x = 5;
	greenLight.y = -5;
	greenLight.z = 0;
	[self.lightSources addObject:greenLight];

	MBECubePointLight *yellowLight = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
	yellowLight.x = -5;
	yellowLight.y = 5;
	yellowLight.z = 0;
	[self.lightSources addObject:yellowLight];

	_objects = [NSMutableArray array];
	MBESphere *sphere = [[MBESphere alloc] initWithDevice:self.device parallels:30 meridians:30];
	[self.objects addObject:sphere];
}

- (void)updateWorldToViewMatrix
{
	_worldToViewMatrix = [MBECamera worldToViewMatrixWithPosition:self.position.xyz target:(vector_float3){0, 0, 0} up:(vector_float3){0, 1, 0}];
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
 DONE 5. Create another primitive shape class (sphere?)
 6. Create 3d rectangle with dynamic height
 DONE 6. Create scene of cubes and allow user to navigate through scene
 7. specify scene using DSL grid
 8. Enable jumping (will require rudimentally collision detection)
 9. Create a "Gesture Recognizer" for keyboard events. I should be able to distinguish between a tap and long press
 10. Create an object that updates scene objects based on past state + user input.

 */

- (void)drawInMTKView:(nonnull MTKView *)view
{
	[self.renderer blockUntilNextRender];

	float prevTime = self.time;
	self.time = CACurrentMediaTime();
	float duration = self.time - prevTime;

	// 1. Handle User Input
	// [self handleUserInput];

	[self updateWorldToViewMatrix];

	// 2. Update objects in Scene
	for (id<MBEObject> light in self.lightSources) {
		[light updateWithTime:self.time duration:duration worldToView:self.worldToViewMatrix];
	}

	for (id<MBEObject> obj in self.objects) {
		[obj updateWithTime:self.time duration:duration worldToView:self.worldToViewMatrix];
	}

	// 3. Render objects to view
	[self.renderer renderObjects:self.objects lightSources:self.lightSources viewPosition:self.position worldToView:self.worldToViewMatrix MTKView:view];
}

#pragma mark - Input Handlers

- (NSString *)normalizedStringFromKeyCode:(NSUInteger)keyCode
{
	switch (keyCode) {
		case 56: return @"shift";
		case 59: return @"left_control";
		case 58: return @"left_option";
		case 55: return @"left_command";
		case 54: return @"right_command";
		case 61: return @"right_option";
		case 60: return @"right_shift";
		case 63: return @"function";

		case 123: return @"left";
		case 124: return @"right";
		case 125: return @"down";
		case 126: return @"up";
		default: return MBECreateStringForKey(keyCode);
	}
}

- (NSSet *)modifierFlagsSetFromEvent:(NSEvent *)event
{
	NSMutableSet *set = [NSMutableSet set];
	if (event.modifierFlags & NSEventModifierFlagShift) {
		[set addObject:@"shift"];
	}
	if (event.modifierFlags & NSEventModifierFlagControl) {
		[set addObject:@"control"];
	}
	if (event.modifierFlags & NSEventModifierFlagOption) {
		[set addObject:@"option"];
	}
	if (event.modifierFlags & NSEventModifierFlagCommand) {
		[set addObject:@"command"];
	}
	if (event.modifierFlags & NSEventModifierFlagFunction) {
		[set addObject:@"function"];
	}

	return [NSSet setWithSet:set];
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)flagsChanged:(NSEvent *)event
{
	self.modifierFlags = [self modifierFlagsSetFromEvent:event];
}

- (void)keyUp:(NSEvent*)event
{
	[self.pressedKeys removeObject:[self normalizedStringFromKeyCode:event.keyCode]];
}

- (void)keyDown:(NSEvent*)event
{
	NSString *key = [self normalizedStringFromKeyCode:event.keyCode];
	[self.pressedKeys addObject:key];
	[self.keyEvents addObject:key];
}

@end
