//
//  MEBKeyboardUtilities.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/11/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

/* Returns string representation of key, if it is printable.
* Ownership follows the Create Rule; that is, it is the caller's
* responsibility to release the returned object. */
NSString *MBECreateStringForKey(CGKeyCode keyCode);

/* Returns key code for given character via the above function, or UINT16_MAX
 * on error. */
CGKeyCode MBEKeyCodeForChar(const char c);

@interface MBEKeyboardUtilities : NSObject

+ (NSString *)normalizedStringFromKeyCode:(NSUInteger)keyCode;

+ (NSSet *)modifierFlagsSetFromEvent:(NSEvent *)event;

@end
