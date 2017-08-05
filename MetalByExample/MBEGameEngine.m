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
#import "MBESphereInstanceArray.h"
#import "MBECubeInstanceArray.h"
#import "CSCurvedPlane.h"

@interface MBEGameEngine ()

@property (nonatomic, strong) MTKView *view;

@property (readonly) id<MTLDevice> device;
@property (nonatomic, strong) MBECamera *camera;
@property (nonatomic, strong) MBERenderer *renderer;

@property (assign) double time;

@property (nonatomic, strong) NSMutableArray <id<MBEPointLightSource>> *lightSources;
@property (nonatomic, strong) NSMutableArray <id<MBEObject, MBERenderable>> *objects;

//@property (nonatomic, strong) NSMutableSet *pressedKeys;
//@property (nonatomic, strong) NSSet *modifierFlags;
//@property (nonatomic, strong) NSMutableArray *keyEvents;

@property (nonatomic, strong) NSMutableSet *activeActions;

@end

@implementation MBEGameEngine

- (instancetype)initWithView:(MTKView *)view;
{
	self = [super init];

	_view = view;
	_device = MTLCreateSystemDefaultDevice();
	_renderer = [[MBERenderer alloc] initWithSize:view.drawableSize device:self.device];
	_camera = [[MBECamera alloc] init];
	_objects = [NSMutableArray array];
	_lightSources = [NSMutableArray array];

	_activeActions = [NSMutableSet set];

	_time = CACurrentMediaTime();

	// Create scene
	[self resetScene];

	return self;
}

- (void)resetScene
{
	_camera = [[MBECamera alloc] init];
	_objects = [NSMutableArray array];
	_lightSources = [NSMutableArray array];
	_activeActions = [NSMutableSet set];
	[self createScene3];
}

- (void)createScene
{
	self.camera.position = (vector_float3){5, 5, 5};

	_objects = [NSMutableArray array];

	int N = 24;
	int low = -1*N/2;
	int high = N/2+1;

	for (int i=low; i<high; i++) {
		for (int j=low; j<high; j++) {
			MBESphere *obj = [[MBESphere alloc] initWithDevice:self.device parallels:20 meridians:20];
			obj.x = i*2;
			obj.y = 0.1 * i * j;
			obj.z = j*2;
			obj.scale = 1.0;
			[self.objects addObject:obj];

//			MBECube *obj = [[MBECube alloc] initWithDevice:self.device];
//			obj.x = i*2;
//			obj.y = 0.1 * i * j;
//			obj.z = j*2;
//			obj.scale = 2.0;
//			[self.objects addObject:obj];

		}
	}

	float radius = 10;
	int numLights = 8;
	for (int i=0; i<numLights; i++) {

		float angle = 2 * M_PI * ((float)i/(float)numLights);
		MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
		light.x = radius*cos(angle);
		light.y = 15;
		light.z = radius*sin(angle);
		[self.lightSources addObject:light];
	}
}

- (void)createScene2
{
	self.camera.position = (vector_float3){5, 5, 5};

	_objects = [NSMutableArray array];

	int N = 50;
	int low = -1*N/2;
	int high = N/2+1;

	int instanceCount = (high - low) * (high - low);
	MBECubeInstanceArray *sphereInstanceArray = [[MBECubeInstanceArray alloc] initWithDevice:self.device instanceCount:instanceCount];

	int index = 0;
	for (int i=low; i<high; i++) {
		for (int j=low; j<high; j++) {
			id<MBEObject> obj = sphereInstanceArray[index++];
			obj.x = i;
			obj.y = 0.05 * ((i * i) + (j * j));
			obj.z = j;
			obj.scale = 1.0;
		}
	}

	[self.objects addObject:sphereInstanceArray];

	float radius = 10;
	int numLights = 8;
	for (int i=0; i<numLights; i++) {
		float percentage = ((float)i/(float)numLights);
		float angle = 2 * M_PI * percentage;

		NSColor *c = [NSColor colorWithHue:percentage saturation:1.0 brightness:1.0 alpha:1.0];
		CGFloat r, g, b;
		[c getRed:&r green:&g blue:&b alpha:NULL];

		MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){r, g, b, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
		light.x = radius*cos(angle);
		light.y = 15;
		light.z = radius*sin(angle);
		[self.lightSources addObject:light];
	}

}

- (void)createScene3
{
	self.camera.position = (vector_float3){0, 5, 5};
	self.camera.front = (vector_float3){0, 0, 1};

	_objects = [NSMutableArray array];

	int N = 150;
	int low = -1*N/2;
	int high = N/2+1;

	int instanceCount = (high - low) * (high - low);
	MBECubeInstanceArray *objInstanceArray = [[MBECubeInstanceArray alloc] initWithDevice:self.device instanceCount:instanceCount];

	int index = 0;
	for (int i=low; i<high; i++) {
		for (int j=low; j<high; j++) {
			id<MBEObject> obj = objInstanceArray[index++];
			obj.x = i;
			obj.y = 0;
			obj.z = j;
			obj.scale = 1.0;
		}
	}

	[self.objects addObject:objInstanceArray];

	float radius = 10;
	int numLights = 10;
	for (int i=0; i<numLights; i++) {
		float percentage = ((float)i/(float)numLights);
		float angle = 2 * M_PI * percentage;

		NSColor *c = [NSColor colorWithHue:percentage saturation:1.0 brightness:1.0 alpha:1.0];
		CGFloat r, g, b;
		[c getRed:&r green:&g blue:&b alpha:NULL];

		MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){r, g, b, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
		light.x = radius*cos(angle);
		light.y = 15;
		light.z = radius*sin(angle);
		[self.lightSources addObject:light];
	}

}





- (void)createSingleSphere
{
	self.camera.position = (vector_float3){0, 0, -30};

	_objects = [NSMutableArray array];
	MBESphere *sphere = [[MBESphere alloc] initWithDevice:self.device parallels:20 meridians:20];
	sphere.scale = 10;
	[self.objects addObject:sphere];

	float radius = 10;
	int numLights = 5;
	for (int i=0; i<numLights; i++) {
		float angle = 2 * M_PI * ((float)i/(float)numLights);
		MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
		light.x = radius*cos(angle);
		light.y = 15;
		light.z = radius*sin(angle);
		[self.lightSources addObject:light];
	}
}

- (void)createSingleCube
{
	self.camera.position = (vector_float3){0, 0, -30};
	_objects = [NSMutableArray array];

	MBECube *cube = [[MBECube alloc] initWithDevice:self.device];
	cube.scale = 10;
	cube.z = 10;
	[self.objects addObject:cube];

	float radius = 10;
	int numLights = 5;
	for (int i=0; i<numLights; i++) {
		float angle = 2 * M_PI * ((float)i/(float)numLights);
		MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
		light.x = radius*cos(angle);
		light.y = 15;
		light.z = radius*sin(angle);
		[self.lightSources addObject:light];
	}
}

- (void)mutliPointLightDemo
{
	self.camera.position = (vector_float3){0, 0, -8};

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

- (void)constantRotation
{
	vector_float3 pos = self.camera.position;
	pos.x = 5 * cos(self.time);
	pos.z = 5 * sin(self.time);
	self.camera.position = pos;
}

#pragma mark <MTKViewDelegate>

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
	[self.renderer drawableSizeWillChange:size];
}

/**
TODO
 DONE 1. Movement with velocity
 2. Objects should move with acceleration (there should be a concept of gravity or force source)
 3. Select object by clicking on it
 4. Outline object using stencil
 DONE 5. Create another primitive shape class (sphere?)
 DONE 6. Create scene of cubes and allow user to navigate through scene
 7. specify scene using DSL grid
 8. Enable jumping (will require rudimentally collision detection)
 10. Create an function that updates scene objects based on past state + user input.

 */

- (void)drawInMTKView:(nonnull MTKView *)view
{
	[self.renderer blockUntilNextRender];

	double currentTime = CACurrentMediaTime();
	double duration = currentTime - self.time;
	self.time = currentTime;

	for (id action in self.activeActions) {
		[self applyAction:action duration:duration];
	}

	matrix_float4x4 worldToViewMatrix = [self.camera worldToViewMatrix];

	// 2. Update objects in Scene
	for (id<MBEObject> light in self.lightSources) {
		[light updateWithTime:self.time duration:duration worldToView:worldToViewMatrix];
	}

	for (id<MBEObject> obj in self.objects) {
		[obj updateWithTime:self.time duration:duration worldToView:worldToViewMatrix];
	}

	// 3. Render objects to view
	vector_float4 viewPosition = {0};
	viewPosition.xyz = self.camera.position;
	viewPosition.w = 1.0;
	[self.renderer renderObjects:self.objects lightSources:self.lightSources viewPosition:viewPosition worldToView:worldToViewMatrix MTKView:view];
}

#pragma mark - Input Handlers

- (NSString *)normalizedStringFromKeyCode:(NSUInteger)keyCode
{
	switch (keyCode) {
		case kVK_Shift: return @"shift";
		case kVK_Control: return @"left_control";
		case kVK_Option: return @"left_option";
		case kVK_Command: return @"left_command";

		case kVK_RightCommand: return @"right_command";
		case kVK_RightOption: return @"right_option";
		case kVK_RightShift: return @"right_shift";
		case kVK_Function: return @"function";

		case kVK_LeftArrow: return @"left";
		case kVK_RightArrow: return @"right";
		case kVK_DownArrow: return @"down";
		case kVK_UpArrow: return @"up";
		case kVK_Escape: return @"escape";


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
}

- (void)keyUp:(NSEvent*)event
{
	id action = [self actionForEvent:event];
	if (action) {
		[self.activeActions removeObject:action];
	}
}

- (void)keyDown:(NSEvent*)event
{
	id action = [self actionForEvent:event];
	if (action) {
		[self.activeActions addObject:action];
	}
}

- (id)actionForEvent:(NSEvent *)event
{
	NSString *key = [self normalizedStringFromKeyCode:event.keyCode];
	if (!key) {
		return nil;
	}
	else if ([key isEqualToString:@"q"] && (event.modifierFlags & NSEventModifierFlagCommand)) {
		return @"QUIT";
	}
	else {
		NSDictionary *actionTable = @{
									  @"w": @"move_forward",
									  @"s": @"move_backward",
									  @"a": @"move_left",
									  @"d": @"move_right",

									  @"left": @"rotate_left",
									  @"right": @"rotate_right",
									  @"up": @"rotate_up",
									  @"down": @"rotate_down",

									  @"t": @"move_up",
									  @"g": @"move_down",

									  @"r": @"RESET",
									  };
		return actionTable[key];
	}
}


// TODO(vivek): create action object that can execute block when in activeActions set. That way I can avoid creating a huge if-else list. The block will capture references to objects it needs to mutate.
- (void)applyAction:(id)action duration:(NSTimeInterval)duration
{
	float rotationSpeed = 2.0 * duration;
	float cameraSpeed = 12.0 * duration;
	vector_float3 cameraFront = self.camera.front;
	vector_float3 cameraPos = self.camera.position;

	float yaw = self.camera.yaw;
	float pitch = self.camera.pitch;

	if ([action isKindOfClass:[NSString class]]) {
		if ([action isEqualToString:@"QUIT"]) {
			[NSApp terminate:self];
		}
		else if ([action isEqualToString:@"RESET"]) {
			[self resetScene];
			cameraFront = self.camera.front;
			cameraPos = self.camera.position;
			yaw = self.camera.yaw;
			pitch = self.camera.pitch;
		}
		else if ([action isEqualToString:@"move_forward"]) {
			cameraPos += cameraSpeed * cameraFront;
		}
		else if ([action isEqualToString:@"move_backward"]) {
			cameraPos -= cameraSpeed * cameraFront;
		}
		else if ([action isEqualToString:@"move_left"]) {
			cameraPos -= simd_normalize(simd_cross(cameraFront, self.camera.up)) * cameraSpeed;
		}
		else if ([action isEqualToString:@"move_right"]) {
			cameraPos += simd_normalize(simd_cross(cameraFront, self.camera.up)) * cameraSpeed;
		}

		else if ([action isEqualToString:@"move_up"]) {
			cameraPos += ((vector_float3){0, 1, 0}) * cameraSpeed;
		}
		else if ([action isEqualToString:@"move_down"]) {
			cameraPos -= ((vector_float3){0, 1, 0}) * cameraSpeed;
		}

		else if ([action isEqualToString:@"rotate_up"]) {
			pitch += rotationSpeed;
		}
		else if ([action isEqualToString:@"rotate_down"]) {
			pitch -= rotationSpeed;
		}
		else if ([action isEqualToString:@"rotate_left"]) {
			yaw -= rotationSpeed;
		}
		else if ([action isEqualToString:@"rotate_right"]) {
			yaw += rotationSpeed;
		}
	}

	self.camera.position = cameraPos;
	float maxPitch = M_PI_2 - 0.05;
	float minPitch = -1 * maxPitch;
	self.camera.pitch = MAX(minPitch, MIN(maxPitch, pitch));
	self.camera.yaw = yaw;
}

@end
