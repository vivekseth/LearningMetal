//
//  GameViewController.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/7/17.
//  Copyright (c) 2017 Vivek Seth. All rights reserved.
//

#import "GameViewController.h"
#import "MBERenderer.h"
#import "MBEGameEngine.h"

@interface GameViewController()

@property (readonly, strong) MTKView *metalView;

@property (nonatomic, strong) MBERenderer *renderer;

@property (nonatomic, strong) MBEGameEngine *engine;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	_metalView = (MTKView *)self.view;
	self.metalView.device = MTLCreateSystemDefaultDevice();
	self.metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;

//	self.renderer = [[MBERenderer alloc] initWithSize:self.metalView.drawableSize];
//	self.metalView.delegate = self.renderer;

	self.engine = [[MBEGameEngine alloc] initWithSize:self.metalView.drawableSize];
	self.metalView.delegate = self.engine;

	
}

- (void)viewDidAppear
{
	[self.view.window makeFirstResponder:self.engine];
}

//- (BOOL)acceptsFirstResponder {
//	return YES;
//}
//
//- (void)keyUp:(NSEvent*)event
//{
//	// [self.renderer keyUp:event];
//}
//
//- (void)keyDown:(NSEvent*)event
//{
//	// [self.renderer keyDown:event];
//}

@end
