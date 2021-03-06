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

	self.engine = [[MBEGameEngine alloc] initWithView:self.metalView];
	self.metalView.delegate = self.engine;
}

- (void)viewDidAppear
{
	[self.view.window makeFirstResponder:self.engine];
}

@end
