//
//  KKMethodCallLoggerProxy.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import "KKMethodCallLoggerProxy.h"
#import "KKAssociatedObjects.h"
#import "KKLogFunction.h"
#import "NSInvocation+PrivateAPI.h"
#import <objc/runtime.h>


static NSString * const kProxyClassPrefix = @"KKMethodCallLoggerProxy_";


@implementation KKMethodCallLoggerProxy

#pragma mark - Generating proxy classes

+ (Class)proxyClassForClass:(Class)klass
{
  NSString *proxyClassName = [NSString stringWithFormat:@"%@%@", kProxyClassPrefix, NSStringFromClass(klass)];
  Class proxyClass;

  if ((proxyClass = NSClassFromString(proxyClassName))) {
    return proxyClass;
  }

  proxyClass = objc_allocateClassPair([NSObject class], [proxyClassName UTF8String], 0);

  for (NSString *toSelectorName in [self proxyInstanceSelectorNames]) {
    NSString *fromSelectorName = [@"proxy_" stringByAppendingString:toSelectorName];
    SEL fromSelector = NSSelectorFromString(fromSelectorName);
    SEL toSelector = NSSelectorFromString(toSelectorName);

    [self copyMethodFromClass:self toClass:proxyClass withFromSelector:fromSelector toSelector:toSelector];
  }

  for (NSString *toSelectorName in [self proxyClassSelectorNames]) {
    NSString *fromSelectorName = [@"proxy_" stringByAppendingString:toSelectorName];
    SEL fromSelector = NSSelectorFromString(fromSelectorName);
    SEL toSelector = NSSelectorFromString(toSelectorName);

    [self copyMethodFromClass:object_getClass(self) toClass:object_getClass(proxyClass) withFromSelector:fromSelector toSelector:toSelector];
  }

  for (NSString *selectorName in [self instanceSelectorNamesToCopyFromClass:klass]) {
    SEL selector = NSSelectorFromString(selectorName);

    [self copyMethodFromClass:klass toClass:proxyClass withFromSelector:selector toSelector:selector];
  }

  objc_registerClassPair(proxyClass);

  return proxyClass;
}

#pragma mark - Methods to copy

- (void)proxy_forwardInvocation:(NSInvocation *)invocation
{
  Class klass = NSClassFromString([[NSStringFromClass(object_getClass(self)) componentsSeparatedByString:kProxyClassPrefix] lastObject]);
  NSString *objectName   = KKAssociatedName(self) ?: NSStringFromClass(klass);
  NSString *selectorName = NSStringFromSelector(invocation.selector);

  KKLog(@"-[%@ %@]", objectName, selectorName);

  [invocation invokeUsingIMP:[klass instanceMethodForSelector:invocation.selector]];
}

- (Class)proxy_class
{
  return NSClassFromString([[NSStringFromClass(object_getClass(self)) componentsSeparatedByString:kProxyClassPrefix] lastObject]);
}

- (Class)proxy_superclass
{
  Class klass = NSClassFromString([[NSStringFromClass(object_getClass(self)) componentsSeparatedByString:kProxyClassPrefix] lastObject]);

  return class_getSuperclass(klass);
}

+ (void)proxy_initialize
{
}

+ (BOOL)proxy_instancesRespondToSelector:(SEL)selector
{
  Class klass = NSClassFromString([[NSStringFromClass(self) componentsSeparatedByString:kProxyClassPrefix] lastObject]);

  return [klass instancesRespondToSelector:selector];
}

+ (NSMethodSignature *)proxy_instanceMethodSignatureForSelector:(SEL)selector
{
  Class klass = NSClassFromString([[NSStringFromClass(self) componentsSeparatedByString:kProxyClassPrefix] lastObject]);

  return [klass instanceMethodSignatureForSelector:selector];
}

#pragma mark - Selector names

+ (NSSet *)instanceSelectorNamesToCopyFromClass:(Class)klass
{
  NSMutableSet *results = [NSMutableSet set];

  [results unionSet:[self instanceSelectorNamesInClass:klass]];
  [results intersectSet:[self instanceSelectorNamesDirectlyInClass:[NSObject class]]];
  [results minusSet:[self proxyInstanceSelectorNames]];

  return results;
}

+ (NSSet *)proxyInstanceSelectorNames
{
  return [NSSet setWithArray:@[@"forwardInvocation:", @"class", @"superclass"]];
}

+ (NSSet *)proxyClassSelectorNames
{
  return [NSSet setWithArray:@[@"initialize", @"instancesRespondToSelector:", @"instanceMethodSignatureForSelector:"]];
}

+ (NSSet *)instanceSelectorNamesInClass:(Class)klass
{
  NSMutableSet *results = [NSMutableSet set];

  for (; ![self classIsBaseClass:klass]; klass = class_getSuperclass(klass)) {
    [results unionSet:[self instanceSelectorNamesDirectlyInClass:klass]];
  }

  return [results copy];
}

+ (NSSet *)instanceSelectorNamesDirectlyInClass:(Class)klass
{
  NSMutableSet *results = [NSMutableSet set];
  unsigned int methodCount;
  Method *methods = class_copyMethodList(klass, &methodCount);

  for (unsigned int i = 0; i < methodCount; i++) {
    NSString *selectorName = NSStringFromSelector(method_getName(methods[i]));

    [results addObject:selectorName];
  }

  return [results copy];
}

#pragma mark - Utility methods

+ (void)copyMethodFromClass:(Class)fromClass toClass:(Class)toClass withFromSelector:(SEL)fromSelector toSelector:(SEL)toSelector
{
  Method method = class_getInstanceMethod(fromClass, fromSelector);
  IMP imp = method_getImplementation(method);
  const char *typeEncoding = method_getTypeEncoding(method);

  class_addMethod(toClass, toSelector, imp, typeEncoding);
}

+ (BOOL)classIsBaseClass:(Class)klass
{
  return klass == [NSObject class] || klass == [NSProxy class] || klass == nil;
}

@end
