//
//  MBEGameEngine.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/9/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <Cocoa/Cocoa.h>

@interface MBEGameEngine : NSResponder<MTKViewDelegate>

- (instancetype)initWithSize:(CGSize)size;

@end
