//
//  MBEKeyHoldRecognizer.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/15/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBEKeyHoldRecognizer.h"
#import "MBEKeyboardUtilities.h"

@interface MBEKeyHoldRecognizer ()

@end

@implementation MBEKeyHoldRecognizer

- (void)reset
{
	if (self.failureDependent) {
		[self.failureDependent.eventQueue addObjectsFromArray:self.eventQueue];
	}

	self.state = MBEActionRecognizerStatePossible;
	[self.eventQueue removeAllObjects];
}

- (void)setState:(MBEActionRecognizerState)state
{
	[super setState:state];
	NSLog(@"setState: %d", (int)state);
}

- (void)update
{
	if (self.state == MBEActionRecognizerStatePossible) {
		// only move to began if needed
		// call target

		if (self.eventQueue.count == 0) {
			return;
		}

		// If key up during possible, reset state and return.
		for (NSEvent *event in self.eventQueue) {
			if (event.type == NSEventTypeKeyUp) {
				self.state = MBEActionRecognizerStateCancelled;
			}
		}

		NSTimeInterval startTimestamp = [(NSEvent *)self.eventQueue[0] timestamp];
		NSTimeInterval endTimestamp = [[NSProcessInfo processInfo] systemUptime];
		NSTimeInterval delta = endTimestamp - startTimestamp;

		NSTimeInterval THRESHOLD = .13;

		if (delta > THRESHOLD) {
			// Consume keyDown events.
			[self.eventQueue removeAllObjects];
			NSLog(@"delta: %f", (float)delta);
			self.state = MBEActionRecognizerStateBegan;
		}
	}
	else if (self.state == MBEActionRecognizerStateBegan || self.state == MBEActionRecognizerStateChanged) {
		// move to ended, or cancelled
		// call target

		// If key up during began, reset state and return.
		for (NSEvent *event in self.eventQueue) {
			if (event.type == NSEventTypeKeyUp) {
				self.state = MBEActionRecognizerStateEnded;
				return;
			}
			else {
				self.state = MBEActionRecognizerStateChanged;
			}
		}
	}
	else if (self.state == MBEActionRecognizerStateEnded || self.state == MBEActionRecognizerStateCancelled) {
		// move to possible
		[self reset];
	}
}

- (void)keyUp:(NSEvent*)event
{
	NSString *pressedKey = [MBEKeyboardUtilities normalizedStringFromKeyCode:event.keyCode];
	if ([self.key isEqualToString:pressedKey]) {
		[self.eventQueue addObject:event];
	}
}

- (void)keyDown:(NSEvent*)event
{
	NSString *pressedKey = [MBEKeyboardUtilities normalizedStringFromKeyCode:event.keyCode];
	if ([self.key isEqualToString:pressedKey]) {
		[self.eventQueue addObject:event];
	}
}

@end
