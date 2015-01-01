//
//  KKSwizzler.h
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2014-12-31.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KKSwizzler : NSObject

+ (void)swizzle:(SEL)selector;

@end
