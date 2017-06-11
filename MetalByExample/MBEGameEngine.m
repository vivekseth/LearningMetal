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

@interface MBEGameEngine ()

@property (readonly) id<MTLDevice> device;
@property (nonatomic, strong) MBERenderer *renderer;

// Camera
@property (nonatomic) float rotY;
@property (nonatomic) vector_float4 position;

@property (assign) float time;
@property (nonatomic) matrix_float4x4 worldToViewMatrix;
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

	const vector_float4 cameraTranslation = {0, -5, -5, 1};
	self.position = cameraTranslation;
	[self updateWorldToViewMatrix];

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

	return self;
}

// - (matrix_float4x4)worldToViewMatrixWith

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
		vector_float4 pos = {self.position.x, self.position.y, self.position.z, 1};

		vector_float3 rotationAxis = {0, 1, 0};
		matrix_float4x4 rotationMatrix = matrix_float4x4_rotation(rotationAxis, -self.rotY);
		vector_float4 xVector = {1, 0, 0, 1};
		// vector_float4 yVector = {0, 1, 0, 1};
		vector_float4 zVector = {0, 0, 1, 1};

		float factor = 0.5;
		if ([self.modifierFlags containsObject:@"shift"]) {
			factor = 2.0;
		}

		if ([self.pressedKeys containsObject:@"x"]) {
			if ([key isEqualToString:@"up"]) {
				pos += factor * matrix_multiply(rotationMatrix, xVector);
			}
			else if ([key isEqualToString:@"down"]) {
				pos -= factor * matrix_multiply(rotationMatrix, xVector);
			}
		}

		if ([self.pressedKeys containsObject:@"y"]) {
			if ([key isEqualToString:@"up"]) {
				pos.y -= factor;
			}
			else if ([key isEqualToString:@"down"]) {
				pos.y += factor;
			}
		}

		if ([self.pressedKeys containsObject:@"z"]) {
			if ([key isEqualToString:@"up"]) {
				pos += factor * matrix_multiply(rotationMatrix, zVector);
			}
			else if ([key isEqualToString:@"down"]) {
				pos -= factor * matrix_multiply(rotationMatrix, zVector);
			}
		}

		if ([key isEqualToString:@"left"]) {
			self.rotY += 0.01 * factor * M_PI;
		}
		else if ([key isEqualToString:@"right"]) {
			self.rotY -= 0.01 * factor * M_PI;
		}

		self.position = pos;

		[self updateWorldToViewMatrix];
	}
	[self.keyEvents removeAllObjects];

	// 2. Update objects in Scene
	matrix_float4x4 worldToProjectionMatrix = matrix_multiply(self.renderer.viewToProjectionMatrix, self.worldToViewMatrix);

	for (id<MBEObject> obj in self.objects) {
		[obj updateWithTime:self.time duration:duration viewProjectionMatrix:worldToProjectionMatrix];
	}

	// 3. Render objects to view
	[self.renderer renderObjects:self.objects MTKView:view];
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
