//
//  MBEActionRecognizer.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/15/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBEActionRecognizer.h"

@implementation MBEActionRecognizer

- (instancetype)init
{
	self = [super init];

	_eventQueue = [NSMutableArray array];
	_state = MBEActionRecognizerStatePossible;

	return self;
}

- (void)reset
{
	self.state = MBEActionRecognizerStatePossible;
}

- (void)requiresFailureOf:(MBEActionRecognizer *)actionRecognizer
{
	self.failureDependency = actionRecognizer;
	actionRecognizer.failureDependent = self;
}

- (void)update
{
	
}

- (void)flagsChanged:(NSEvent *)event
{

}

- (void)keyUp:(NSEvent*)event
{

}

- (void)keyDown:(NSEvent*)event
{

}

@end

