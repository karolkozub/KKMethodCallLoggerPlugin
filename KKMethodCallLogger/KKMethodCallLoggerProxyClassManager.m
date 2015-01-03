//
//  KKMethodCallLoggerProxyClassManager.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import "KKMethodCallLoggerProxyClassManager.h"
#import "KKAssociatedObjects.h"
#import "KKLogFunction.h"
#import "NSInvocation+PrivateAPI.h"
#import <objc/runtime.h>


@implementation KKMethodCallLoggerProxyClassManager

#pragma mark - Generating proxy classes

+ (Class)proxyClassForClass:(Class)klass
{
  NSString *proxyClassName = [NSString stringWithFormat:@"KKMethodCallLoggerProxyClassFor%@", NSStringFromClass(klass)];
  Class proxySuperclass = [self proxySuperclassForClass:class_getSuperclass(klass)];
  Class proxyClass;

  if ((proxyClass = NSClassFromString(proxyClassName))) {
    return proxyClass;
  }

  proxyClass = objc_allocateClassPair(proxySuperclass, [proxyClassName UTF8String], 0);

  [self copyMethodFromClass:self                  toClass:proxyClass                  withFromSelector:@selector(proxy_forwardInvocation:) toSelector:@selector(forwardInvocation:)];
  [self copyMethodFromClass:self                  toClass:proxyClass                  withFromSelector:@selector(proxy_class)              toSelector:@selector(class)];
  [self copyMethodFromClass:self                  toClass:proxyClass                  withFromSelector:@selector(proxy_superclass)         toSelector:@selector(superclass)];
  [self copyMethodFromClass:object_getClass(self) toClass:object_getClass(proxyClass) withFromSelector:@selector(proxy_initialize)         toSelector:@selector(initialize)];

  for (NSString *selectorName in [self basicInstanceSelectorNamesDirectlyContainedInClass:klass]) {
    SEL selector = NSSelectorFromString(selectorName);
    [self copyMethodFromClass:klass toClass:proxyClass withFromSelector:selector toSelector:selector];
  }

  objc_registerClassPair(proxyClass);

  return proxyClass;
}

+ (Class)proxySuperclassForClass:(Class)klass
{
  if ([self classIsBaseClass:klass] || klass == nil) {
    return klass;
  }

  NSString *proxySuperclassName = [NSString stringWithFormat:@"KKMethodCallLoggerProxySuperclassFor%@", NSStringFromClass(klass)];
  Class proxySuperSuperclass = [self proxySuperclassForClass:class_getSuperclass(klass)];
  Class proxySuperclass;

  if ((proxySuperclass = NSClassFromString(proxySuperclassName))) {
    return proxySuperclass;
  }

  proxySuperclass = objc_allocateClassPair(proxySuperSuperclass, [proxySuperclassName UTF8String], 0);

  [self copyMethodFromClass:self                  toClass:proxySuperclass                  withFromSelector:@selector(superproxy_forwardInvocation:) toSelector:@selector(forwardInvocation:)];
  [self copyMethodFromClass:self                  toClass:proxySuperclass                  withFromSelector:@selector(superproxy_class)              toSelector:@selector(class)];
  [self copyMethodFromClass:self                  toClass:proxySuperclass                  withFromSelector:@selector(proxy_superclass)              toSelector:@selector(superclass)];
  [self copyMethodFromClass:object_getClass(self) toClass:object_getClass(proxySuperclass) withFromSelector:@selector(proxy_initialize)              toSelector:@selector(initialize)];

  for (NSString *selectorName in [self basicInstanceSelectorNamesDirectlyContainedInClass:klass]) {
    SEL selector = NSSelectorFromString(selectorName);
    [self copyMethodFromClass:klass toClass:proxySuperclass withFromSelector:selector toSelector:selector];
  }

  objc_registerClassPair(proxySuperclass);

  return proxySuperclass;
}

#pragma mark - Copying methods

+ (void)copyMethodFromClass:(Class)fromClass toClass:(Class)toClass withFromSelector:(SEL)fromSelector toSelector:(SEL)toSelector
{
  Method method = class_getInstanceMethod(fromClass, fromSelector);
  IMP imp = method_getImplementation(method);
  const char *typeEncoding = method_getTypeEncoding(method);

  class_addMethod(toClass, toSelector, imp, typeEncoding);
}

#pragma mark - Methods to copy

- (void)proxy_forwardInvocation:(NSInvocation *)invocation
{
  NSString *objectName   = KKAssociatedName(self) ?: NSStringFromClass([self class]);
  NSString *selectorName = NSStringFromSelector(invocation.selector);
  Class originalClass = [self class];
  Method method = class_getInstanceMethod(originalClass, invocation.selector);
  IMP imp = method_getImplementation(method);

  KKLog(@"-[%@ %@]", objectName, selectorName);

  [invocation invokeUsingIMP:imp];
}

- (void)superproxy_forwardInvocation:(NSInvocation *)invocation
{
  Class originalClass = [self class];
  Class proxyClass    = KKAssociatedProxyClass(self);
  Class superclass    = class_getSuperclass(originalClass);
  Method superMethod = class_getInstanceMethod(superclass, invocation.selector);
  IMP superImp = method_getImplementation(superMethod);

  object_setClass(self, originalClass);
  [invocation invokeUsingIMP:superImp];
  object_setClass(self, proxyClass);
}

- (Class)proxy_class
{
  return NSClassFromString([NSStringFromClass(object_getClass(self)) substringFromIndex:[@"KKMethodCallLoggerProxyClassFor" length]]);
}

- (Class)superproxy_class
{
  return NSClassFromString([NSStringFromClass(object_getClass(self)) substringFromIndex:[@"KKMethodCallLoggerProxySuperclassFor" length]]);
}

- (Class)proxy_superclass
{
  return class_getSuperclass([self class]);
}

+ (void)proxy_initialize
{
}

#pragma mark - Basic instance selector names

+ (NSSet *)basicInstanceSelectorNames
{
  static NSSet *basicInstanceSelectorNames;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    basicInstanceSelectorNames = [NSSet setWithArray:@[@"isEqual:", @"hash", @"self", @"isKindOfClass:", @"isMemberOfClass:", @"respondsToSelector:", @"conformsToProtocol:", @"methodSignatureForSelector:", @"description", @"debugDescription", @"performSelector:", @"doesNotRecognizeSelector:", @"performSelector:withObject:", @"performSelector:withObject:withObject:", @"isProxy", @"retain", @"release", @"autorelease", @"retainCount", @"zone", @"dealloc", @"finalize", @"_tryRetain", @"_isDeallocating", @"allowsWeakReference", @"retainWeakReference"]];
  });

  return basicInstanceSelectorNames;
}

+ (NSSet *)basicInstanceSelectorNamesDirectlyContainedInClass:(Class)klass
{
  NSMutableSet *results = [NSMutableSet set];
  unsigned int methodCount;
  Method *methods = class_copyMethodList(klass, &methodCount);

  for (unsigned int i = 0; i < methodCount; i++) {
    NSString *selectorName = NSStringFromSelector(method_getName(methods[i]));

    if ([[self basicInstanceSelectorNames] containsObject:selectorName]) {
      [results addObject:selectorName];
    }
  }

  return results;
}

#pragma mark - Base class

+ (BOOL)classIsBaseClass:(Class)klass
{
  return klass == [NSObject class] || klass == [NSProxy class];
}

@end
