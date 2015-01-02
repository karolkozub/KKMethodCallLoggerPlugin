//
//  KKTestProxy.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import "KKTestProxy.h"


@implementation KKTestProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
  return [NSProxy methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{}

@end
