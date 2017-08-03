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
#import "MBEPlane.h"

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
	_objects = [NSMutableArray array];
	_lightSources = [NSMutableArray array];
	_activeActions = [NSMutableSet set];
	[self createGameLevel];
	[self createWhiteLightRing];
}

- (void)createSceneWithPlane
{
	self.camera.position = (vector_float3){0, 5, 5};
	self.camera.front = (vector_float3){0, 0, 1};

	MBEPlane *plane = [[MBEPlane alloc] initWithDevice:self.device];
	plane.width = 20;
	plane.height = 20;
	plane.rotationMatrix = matrix_float4x4_rotation((vector_float3){0, 0, 1}, -1 * M_PI / 2.0);
	[self.objects addObject:plane];
}

- (void)createGameLevel
{
	self.camera.position = (vector_float3){0, 5, 5};
	self.camera.front = (vector_float3){0, 0, 1};

	NSUInteger level[8][8] = {
		{0, 0, 0, 0, 0, 0, 1, 1},
		{0, 1, 1, 1, 0, 0, 1, 1},
		{0, 1, 0, 1, 0, 0, 1, 1},
		{0, 1, 1, 1, 0, 0, 1, 1},
		{0, 0, 1, 0, 0, 0, 0, 1},
		{0, 0, 1, 1, 0, 0, 0, 1},
		{0, 1, 0, 1, 1, 1, 1, 1},
		{0, 1, 1, 1, 1, 0, 0, 0},
	};
	NSUInteger *levelPointer = (NSUInteger *)level;

	BOOL (^checkLevel)(int i, int j) = ^BOOL(int i, int j) {
		if (i < 0 || j < 0) {
			return NO;
		}
		else if (i >= 8 || j >= 8) {
			return NO;
		}
		else {
			return levelPointer[i * 8 + j];
		}
	};

	for (int i=0; i<8; i++) {
		for (int j=0; j<8; j++) {
			if (checkLevel(i, j)) {
				[self addGameTileWithX:i y:0 z:j];
				if (!checkLevel(i + 1, j)) {
					[self addWallWithX:i z:j option:0];
				}
				if (!checkLevel(i - 1, j)) {
					[self addWallWithX:i z:j option:1];
				}
				if (!checkLevel(i, j + 1)) {
					[self addWallWithX:i z:j option:2];
				}
				if (!checkLevel(i, j - 1)) {
					[self addWallWithX:i z:j option:3];
				}
			}
		}
	}
}

- (void)addWallWithX:(NSInteger)x z:(NSUInteger)z option:(NSUInteger)option
{
	if (option == 0) {
		MBEPlane *plane = [[MBEPlane alloc] initWithDevice:self.device];
		plane.x = (x + 0.5) * 20;
		plane.y = 10;
		plane.z = z * 20;

		plane.width = 20;
		plane.height = 20;
		plane.rotationMatrix = matrix_float4x4_rotation((vector_float3){0, 0, 1}, M_PI / -2.0);
		[self.objects addObject:plane];
	}

	else if (option == 1) {
		MBEPlane *plane = [[MBEPlane alloc] initWithDevice:self.device];
		plane.x = (x - 0.5) * 20;
		plane.y = 10;
		plane.z = z * 20;

		plane.width = 20;
		plane.height = 20;
		plane.rotationMatrix = matrix_float4x4_rotation((vector_float3){0, 0, 1}, M_PI / 2.0);
		[self.objects addObject:plane];
	}


	else if (option == 2) {
		MBEPlane *plane = [[MBEPlane alloc] initWithDevice:self.device];
		plane.x = x * 20;
		plane.y = 10;
		plane.z = (z + 0.5) * 20;

		plane.width = 20;
		plane.height = 20;
		plane.rotationMatrix = matrix_float4x4_rotation((vector_float3){1, 0, 0}, M_PI / 2.0);
		[self.objects addObject:plane];
	}

	else if (option == 3) {
		MBEPlane *plane = [[MBEPlane alloc] initWithDevice:self.device];
		plane.x = x * 20;
		plane.y = 10;
		plane.z = (z - 0.5) * 20;

		plane.width = 20;
		plane.height = 20;
		plane.rotationMatrix = matrix_float4x4_rotation((vector_float3){1, 0, 0}, M_PI / -2.0);
		[self.objects addObject:plane];
	}
}


- (void)addGameTileWithX:(NSInteger)x y:(NSUInteger)y z:(NSUInteger)z
{
	MBEPlane *plane = [[MBEPlane alloc] initWithDevice:self.device];

	plane.x = x * 20;
	plane.z = z * 20;

	plane.width = 20;
	plane.height = 20;
	[self.objects addObject:plane];
}




- (void)createScene
{
	self.camera.position = (vector_float3){5, 5, 5};

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
		}
	}
}

- (void)createScene2
{
	self.camera.position = (vector_float3){5, 5, 5};

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
}

- (void)createScene3
{
	self.camera.position = (vector_float3){0, 5, 5};
	self.camera.front = (vector_float3){0, 0, 1};

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
}

- (void)createSingleSphere
{
	self.camera.position = (vector_float3){0, 0, -30};

	_objects = [NSMutableArray array];
	MBESphere *sphere = [[MBESphere alloc] initWithDevice:self.device parallels:20 meridians:20];
	sphere.scale = 10;
	[self.objects addObject:sphere];
}

- (void)createSingleCube
{
	self.camera.position = (vector_float3){0, 0, -30};

	MBECube *cube = [[MBECube alloc] initWithDevice:self.device];
	cube.scale = 10;
	cube.z = 10;
	[self.objects addObject:cube];
}

- (void)createWhiteLightRing
{
	float radius = 10;
	int numLights = 1;
	for (int i=0; i<numLights; i++) {
		float angle = 2 * M_PI * ((float)i/(float)numLights);
		MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){1, 1, 1, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
		light.x = radius*cos(angle);
		light.y = 15;
		light.z = radius*sin(angle);
		[self.lightSources addObject:light];
	}
}

- (void)createColoredLightRing
{
	float radius = 15;
	int numLights = 20;
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

- (void)createRandomColoredLightGrid
{
	int N = 4;
	int low = -1*N/2;
	int high = N/2+1;
	for (int i=low; i<high; i++) {
		for (int j=low; j<high; j++) {
			CGFloat r, g, b;
			r = 1;
			g = 1;
			b = 1;
			MBECubePointLight *light = [[MBECubePointLight alloc] initWithDevice:self.device color:(vector_float4){r, g, b, 1} strength:1.0 K:1.0 L:0.07 Q:0.017];
			light.x = i * 20;
			light.y = 15;
			light.z = j * 20;
			[self.lightSources addObject:light];
		}
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

	// make one light track camera. 
	self.lightSources[0].x = self.camera.position.x;
	self.lightSources[0].y = self.camera.position.y;
	self.lightSources[0].z = self.camera.position.z;

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
