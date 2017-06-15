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
#import "MBELightingSphere.h"
#import "MBEKeyboardUtilities.h"

@interface MBEGameEngine ()

@property (readonly) id<MTLDevice> device;
@property (nonatomic, strong) MBERenderer *renderer;

// Camera
@property (nonatomic) float rotY;
@property (nonatomic) vector_float4 position;

@property (assign) float time;
@property (nonatomic) matrix_float4x4 worldToViewMatrix;

@property (nonatomic, strong) id<MBEObject> lightSource;
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

	// MBELightingSphere *sphere = [[MBELightingSphere alloc] init];

	self.lightSource = [[MBECube alloc] initWithDevice:self.device];
	self.lightSource.x = 5;
	self.lightSource.y = 5;
	self.lightSource.z = 0;

//	const vector_float4 cameraTranslation = {0, 0, -8, 1.0};
//	self.position = cameraTranslation;

	// Create scene
	[self createSingleLightingSphere];

	[self updateWorldToViewMatrix];

	return self;
}

- (void)createScene
{
	const vector_float4 cameraTranslation = {0, -5, -5, 1};
	self.position = cameraTranslation;

	_objects = [NSMutableArray array];

	int N = 32;
	int low = -1*N/2;
	int high = N/2+1;

	for (int i=low; i<high; i++) {
		for (int j=low; j<high; j++) {
			MBECube *cube = [[MBECube alloc] initWithDevice:self.device];
			cube.x = i*2;
			cube.y = 0.1 * i * j;
			cube.z = j*2;
			[self.objects addObject:cube];
		}
	}
}

- (void)createSingleSphere
{
	const vector_float4 cameraTranslation = {0, 0, -8, 1.5};
	self.position = cameraTranslation;

	_objects = [NSMutableArray array];
	MBESphere *sphere = [[MBESphere alloc] initWithDevice:self.device parallels:20 meridians:20];
	[self.objects addObject:sphere];
}

- (void)createSingleLightingSphere
{
	const vector_float4 cameraTranslation = {0, 0, -8, 1.5};
	self.position = cameraTranslation;

	_objects = [NSMutableArray array];
	MBELightingSphere *sphere = [[MBELightingSphere alloc] initWithDevice:self.device parallels:20 meridians:20];
	[self.objects addObject:sphere];
}

- (void)updateWorldToViewMatrix
{
	const vector_float3 axis = {0, 1, 0};
	const vector_float3 translation = {self.position.x, self.position.y, self.position.z};
	_worldToViewMatrix = matrix_multiply(matrix_float4x4_rotation(axis, self.rotY), matrix_float4x4_translation(translation));
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

	// quit if needed
	if ([self.modifierFlags containsObject:@"command"] && [self.pressedKeys containsObject:@"q"]) {
		[NSApp terminate:self];
	}

	// consume all remaining key events.
	for (NSString *key in self.keyEvents) {
		vector_float4 pos = {self.lightSource.x, self.lightSource.y, self.lightSource.z, 1};

		vector_float3 rotationAxis = {0, 1, 0};
		matrix_float4x4 rotationMatrix = matrix_float4x4_rotation(rotationAxis, -self.rotY);
		vector_float4 xVector = {1, 0, 0, 1};
		vector_float4 yVector = {0, 1, 0, 1};
		vector_float4 zVector = {0, 0, 1, 1};

		float factor = 0.5;
		if ([self.modifierFlags containsObject:@"shift"]) {
			factor = 2.0;
		}

		float direction = 0.0;
		if ([key isEqualToString:@"up"]) {
			direction = 1.0;
		}
		else if ([key isEqualToString:@"down"]) {
			direction = -1.0;
		}

		if ([self.pressedKeys containsObject:@"x"]) {
			pos += direction * factor * matrix_multiply(rotationMatrix, xVector);
		}

		if ([self.pressedKeys containsObject:@"y"]) {
			pos += -1 * direction * factor * yVector;
		}

		if ([self.pressedKeys containsObject:@"z"]) {
			pos += direction * factor * matrix_multiply(rotationMatrix, zVector);
		}

		if ([key isEqualToString:@"left"]) {
			self.rotY += 0.01 * factor * M_PI;
		}
		else if ([key isEqualToString:@"right"]) {
			self.rotY -= 0.01 * factor * M_PI;
		}

		self.lightSource.x = pos.x;
		self.lightSource.y = pos.y;
		self.lightSource.z = pos.z;

		[self updateWorldToViewMatrix];
	}
	[self.keyEvents removeAllObjects];

	// 2. Update objects in Scene


	[self.lightSource updateWithTime:self.time duration:duration worldToView:self.worldToViewMatrix viewToProjection:self.renderer.viewToProjectionMatrix cameraPosition:self.position];

	for (id<MBEObject> obj in self.objects) {
		
		[obj updateWithTime:self.time duration:duration worldToView:self.worldToViewMatrix viewToProjection:self.renderer.viewToProjectionMatrix cameraPosition:self.position lightSourcePosition:(vector_float4){self.lightSource.x, self.lightSource.y, self.lightSource.z, 1.0}];
	}

	// 3. Render objects to view
	NSArray *objects = [self.objects arrayByAddingObject:self.lightSource];
	[self.renderer renderObjects:objects MTKView:view];
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
	NSLog(@"%@", self.modifierFlags);
}

- (void)keyUp:(NSEvent*)event
{
	[self.pressedKeys removeObject:[self normalizedStringFromKeyCode:event.keyCode]];
	NSLog(@"%@", self.pressedKeys);
}

- (void)keyDown:(NSEvent*)event
{
	NSString *key = [self normalizedStringFromKeyCode:event.keyCode];
	[self.pressedKeys addObject:key];
	[self.keyEvents addObject:key];
	NSLog(@"%@", self.pressedKeys);
}

@end
