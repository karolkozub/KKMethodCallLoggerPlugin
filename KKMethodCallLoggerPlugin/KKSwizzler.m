//
//  KKSwizzler.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2014-12-31.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import "KKSwizzler.h"
#import <objc/runtime.h>


@implementation KKSwizzler

+ (void)swizzle:(SEL)sourceSelector
{
  @try {
    NSArray *components = [NSStringFromSelector(sourceSelector) componentsSeparatedByString:@"$"];

    Class sourceClass = self;
    Method sourceMethod = class_getInstanceMethod(sourceClass, sourceSelector);
    Class destinationClass = NSClassFromString(components[0]);
    SEL destinationSelector = NSSelectorFromString(components[1]);

    class_addMethod(destinationClass, sourceSelector, method_getImplementation(sourceMethod), method_getTypeEncoding(sourceMethod));

    Method originalMethod = class_getInstanceMethod(destinationClass, sourceSelector);
    Method swizzledMethod = class_getInstanceMethod(destinationClass, destinationSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);

  } @catch (NSException *exception) {
    NSLog(@"KKSwizzler: Failed to swizzle %@. %@", NSStringFromSelector(sourceSelector), exception);
  }
}

@end
