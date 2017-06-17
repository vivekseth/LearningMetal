//
//  MBEActionRecognizer.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/15/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, MBEActionRecognizerState) {
	MBEActionRecognizerStatePossible,
	MBEActionRecognizerStateBegan,
	MBEActionRecognizerStateChanged,
	MBEActionRecognizerStateEnded,
	MBEActionRecognizerStateCancelled,
	MBEActionRecognizerStateFailed,
	MBEActionRecognizerStateRecognized
};

@interface MBEActionRecognizer : NSObject

// Discrete:
// Possible -> Recognized
// or
// Possible -> Failed

// Continuous:
// Possible -> Began -> [Changed] -> Ended
// Possible -> Began -> [Changed] -> Cancelled
@property (nonatomic) MBEActionRecognizerState state;

// Queue up events so they can be sent to other ARs if necessary.
@property (nonatomic, strong) NSMutableArray *eventQueue;

@property (nonatomic, strong) MBEActionRecognizer *failureDependency;
@property (nonatomic, strong) MBEActionRecognizer *failureDependent;
- (void)requiresFailureOf:(MBEActionRecognizer *)actionRecognizer;

- (void)reset;

- (void)update;

- (void)flagsChanged:(NSEvent *)event;

- (void)keyUp:(NSEvent*)event;

- (void)keyDown:(NSEvent*)event;

@end
