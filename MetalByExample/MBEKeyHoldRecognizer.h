//
//  MBEKeyHoldRecognizer.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/15/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBEActionRecognizer.h"

@interface MBEKeyHoldRecognizer : MBEActionRecognizer

@property (nonatomic, strong) NSString *key;

@end
