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

@interface MBEGameEngine () <MBERendererDelegate>

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
	_view.framebufferOnly = NO;
	_device = MTLCreateSystemDefaultDevice();
	_renderer = [[MBERenderer alloc] initWithSize:view.drawableSize device:self.device];
	_camera = [[MBECamera alloc] init];
	_objects = [NSMutableArray array];
	_lightSources = [NSMutableArray array];

	_activeActions = [NSMutableSet set];

	_time = CACurrentMediaTime();

	self.renderer.delegate = self;

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

- (void)createScene3
{
	self.camera.position = (vector_float3){0, 0, 0};
	self.camera.front = (vector_float3){0, 0, 1};

	_objects = [NSMutableArray array];

    CSCurvedPlane *plane = [[CSCurvedPlane alloc] initWithDevice:self.device];
    [plane createBuffers];
    [self.objects addObject:plane];

    // This can be used to find the focal length in pixels. 
    CSCurvedPlane *plane2 = [[CSCurvedPlane alloc] initWithDevice:self.device];
    plane2.fx = ^CGFloat(CGFloat u, CGFloat v) {
        return u;
    };
    plane2.fy = ^CGFloat(CGFloat u, CGFloat v) {
        return v;
    };
    plane2.fz = ^CGFloat(CGFloat u, CGFloat v) {
        return 10;
    };
    plane2.uRange = (vector_float2){-0.5, 0.5};
    plane2.vRange = (vector_float2){-1, 0};
    [plane2 createBuffers];
    [self.objects addObject:plane2];

}


#pragma mark <MBERendererDelegate>

- (void)renderer:(MBERenderer *)renderer didCaptureScreenshot:(NSImage *)screenshot
{
	CGImageRef cgImage = [screenshot CGImageForProposedRect:nil context:nil hints:nil];

	NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	NSData *data = [imgRep representationUsingType:NSPNGFileType properties:@{}];
	// BOOL success = [data writeToFile: @"~/Desktop/screenshot.png" atomically: NO];

	NSError *error = nil;
	BOOL success = [data writeToURL:[NSURL fileURLWithPath:@"screenshot.png"] options:NSDataWritingAtomic error:&error];

	if (!success) {
		NSLog(@"fail");
	}
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

- (void)captureFrame
{
	self.renderer.screenshotRequested = YES;
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
		case kVK_Space: return @"space";


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

	if ([action isEqualToString:@"capture"]) {
		// CAPTURE FRAME
		[self captureFrame];
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
									  @"space": @"capture",
									  };
		return actionTable[key];
	}
}


// TODO(vivek): create action object that can execute block when in activeActions set. That way I can avoid creating a huge if-else list. The block will capture references to objects it needs to mutate.
- (void)applyAction:(id)action duration:(NSTimeInterval)duration
{
//	float rotationSpeed = 2.0 * duration;
//	float cameraSpeed = 12.0 * duration;
//	vector_float3 cameraFront = self.camera.front;
//	vector_float3 cameraPos = self.camera.position;
//
//	float yaw = self.camera.yaw;
//	float pitch = self.camera.pitch;
//
//	if ([action isKindOfClass:[NSString class]]) {
//		if ([action isEqualToString:@"QUIT"]) {
//			[NSApp terminate:self];
//		}
//		else if ([action isEqualToString:@"RESET"]) {
//			[self resetScene];
//			cameraFront = self.camera.front;
//			cameraPos = self.camera.position;
//			yaw = self.camera.yaw;
//			pitch = self.camera.pitch;
//		}
//		else if ([action isEqualToString:@"move_forward"]) {
//			cameraPos += cameraSpeed * cameraFront;
//		}
//		else if ([action isEqualToString:@"move_backward"]) {
//			cameraPos -= cameraSpeed * cameraFront;
//		}
//		else if ([action isEqualToString:@"move_left"]) {
//			cameraPos -= simd_normalize(simd_cross(cameraFront, self.camera.up)) * cameraSpeed;
//		}
//		else if ([action isEqualToString:@"move_right"]) {
//			cameraPos += simd_normalize(simd_cross(cameraFront, self.camera.up)) * cameraSpeed;
//		}
//
//		else if ([action isEqualToString:@"move_up"]) {
//			cameraPos += ((vector_float3){0, 1, 0}) * cameraSpeed;
//		}
//		else if ([action isEqualToString:@"move_down"]) {
//			cameraPos -= ((vector_float3){0, 1, 0}) * cameraSpeed;
//		}
//
//		else if ([action isEqualToString:@"rotate_up"]) {
//			pitch += rotationSpeed;
//		}
//		else if ([action isEqualToString:@"rotate_down"]) {
//			pitch -= rotationSpeed;
//		}
//		else if ([action isEqualToString:@"rotate_left"]) {
//			yaw -= rotationSpeed;
//		}
//		else if ([action isEqualToString:@"rotate_right"]) {
//			yaw += rotationSpeed;
//		}
//	}
//
//	self.camera.position = cameraPos;
//	float maxPitch = M_PI_2 - 0.05;
//	float minPitch = -1 * maxPitch;
//	self.camera.pitch = MAX(minPitch, MIN(maxPitch, pitch));
//	self.camera.yaw = yaw;
}

@end
