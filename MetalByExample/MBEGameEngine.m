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
#import "MBEActionRecognizer.h"
#import "MBEKeyHoldRecognizer.h"

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

@property (nonatomic, strong) NSMutableArray *eventQueue;

@property (nonatomic, strong) MBEKeyHoldRecognizer *keyHoldRecognizer;

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

	_keyHoldRecognizer = [[MBEKeyHoldRecognizer alloc] init];
	self.keyHoldRecognizer.key = @"a";

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
	// [self.renderer blockUntilNextRender];

	float prevTime = self.time;
	self.time = CACurrentMediaTime();
	float duration = self.time - prevTime;

	// 1. Handle User Input
	[self handleUserInput];

	// 2. Update objects in Scene
	[self.lightSource updateWithTime:self.time duration:duration worldToView:self.worldToViewMatrix viewToProjection:self.renderer.viewToProjectionMatrix cameraPosition:self.position];

	for (id<MBEObject> obj in self.objects) {
		[obj updateWithTime:self.time duration:duration worldToView:self.worldToViewMatrix viewToProjection:self.renderer.viewToProjectionMatrix cameraPosition:self.position lightSourcePosition:(vector_float4){self.lightSource.x, self.lightSource.y, self.lightSource.z, 1.0}];
	}

	// 3. Render objects to view
//	NSArray *objects = [self.objects arrayByAddingObject:self.lightSource];
//	[self.renderer renderObjects:objects MTKView:view];
}

- (void)handleUserInput
{
	[self.keyHoldRecognizer update];

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
}

#pragma mark - Input Handlers

- (BOOL)acceptsFirstResponder {
	return YES;
}

//- (void)flagsChanged:(NSEvent *)event
//{
//	self.modifierFlags = [self.class modifierFlagsSetFromEvent:event];
//	NSLog(@"%@", self.modifierFlags);
//}

- (void)registerHoldRecognizerForKey:(NSString *)key block:(void (^)(void))block
{

}

- (void)detectLongPressForKey:(NSString *)key time:(NSTimeInterval)time block:(void (^)(void))block
{

}




- (void)keyUp:(NSEvent*)event
{
	// NSLog(@"%@, %@", self.pressedKeys, [self.class modifierFlagsSetFromEvent:event]);
	// [self.pressedKeys removeObject:[self.class normalizedStringFromKeyCode:event.keyCode]];

	[self.keyHoldRecognizer keyUp:event];
}

- (void)keyDown:(NSEvent*)event
{
	// NSString *key = [self.class normalizedStringFromKeyCode:event.keyCode];
	// [self.pressedKeys addObject:key];
	// [self.keyEvents addObject:key];
	// NSLog(@"%@, %@", self.pressedKeys, [self.class modifierFlagsSetFromEvent:event]);

	[self.keyHoldRecognizer keyDown:event];
}

@end
