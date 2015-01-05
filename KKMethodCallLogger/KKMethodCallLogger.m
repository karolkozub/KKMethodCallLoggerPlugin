//
//  KKMethodCallLogger.m
//  KKMethodCallLogger
//
//  Created by Karol Kozub on 2014-12-28.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import "KKMethodCallLogger.h"
#import "KKMethodCallLoggerProxy.h"
#import "KKAssociatedObjects.h"
#import "KKLogFunction.h"
#import <objc/runtime.h>


@implementation KKMethodCallLogger

+ (void)startLoggingMethodCallsForObject:(id)object
{
  [self startLoggingMethodCallsForObject:object withName:nil];
}

+ (void)startLoggingMethodCallsForObject:(id)object withName:(NSString *)name
{
  if (object == nil) {
    KKLog(@"KKMethodCallLogger cannot log calls for a nil object.");
    return;
  }

  if (class_isMetaClass(object_getClass(object))) {
    KKLog(@"KKMethodCallLogger doesn't currently support logging class method calls.");
    return;
  }

  if ([object isProxy]) {
    KKLog(@"KKMethodCallLogger doesn't currently support logging method calls for proxy objects.");
    return;
  }

  Class proxyClass = [KKMethodCallLoggerProxy proxyClassForClass:[object class]];

  if (KKAssociatedProxyClass(object) != proxyClass) {
    KKSetAssociatedProxyClass(object, proxyClass);
    object_setClass(object, proxyClass);

    [[self mutableLoggedObjects] addObject:object];
  }

  KKSetAssociatedName(object, name);
}

+ (void)stopLoggingMethodCallsForObject:(id)object
{
  Class objectClass = [object class];
  Class proxyClass  = [KKMethodCallLoggerProxy proxyClassForClass:objectClass];

  if (KKAssociatedProxyClass(object) == proxyClass) {
    object_setClass(object, objectClass);
    KKSetAssociatedName(object, nil);
    KKSetAssociatedProxyClass(object, objectClass);

    [[self mutableLoggedObjects] removeObject:object];
  }
}

+ (void)stopLoggingMethodCallsForAllObjects
{
  for (id object in [[self mutableLoggedObjects] copy]) {
    [self stopLoggingMethodCallsForObject:object];
  }
}

+ (void)listMethodsForClass:(Class)klass
{
  [self listMethodsForClass:klass includingAncestors:NO];
}

+ (void)listMethodsForClass:(Class)klass includingAncestors:(BOOL)includingAncestors
{
  NSMutableString *methodListString = [NSMutableString string];

  for (; klass; klass = includingAncestors ? [klass superclass] : nil) {
    [methodListString appendFormat:@"%@\n", NSStringFromClass(klass)];
    unsigned int methodCount;
    Method *methods = class_copyMethodList(klass, &methodCount);
    NSMutableArray *methodNames = [NSMutableArray array];

    for (unsigned int i = 0; i < methodCount; i++) {
      Method method = methods[i];
      SEL methodSelector = method_getName(method);
      NSString *methodName = NSStringFromSelector(methodSelector);

      [methodNames addObject:methodName];
    }

    [methodNames sortUsingComparator:^NSComparisonResult(NSString *name1, NSString *name2) {
      if ([name1 hasPrefix:@"_"] == [name2 hasPrefix:@"_"]) {
        return [name1 compare:name2];

      } else if ([name1 hasPrefix:@"_"]) {
        return NSOrderedDescending;

      } else {
        return NSOrderedAscending;
      }
    }];

    for (NSString *methodName in methodNames) {
      [methodListString appendFormat:@"  -%@\n", methodName];
    }
  }

  KKLog(@"%@", methodListString);
}

+ (void)listLoggedObjects
{
  NSMutableString *objectListString = [NSMutableString string];

  for (id object in [self mutableLoggedObjects]) {
    NSString *objectName = KKAssociatedName(object);
    [objectListString appendFormat:@"<%@: %p>%@%@\n", NSStringFromClass([object class]), object, objectName ? @" ": @"", objectName ?: @""];
  }

  KKLog(@"%@", objectListString);
}

+ (void)showHelpMessage
{
  NSString *helpString = @"KKMethodCallLogger commands:\n"
  @"  mcl-log <object>         -- Start logging method calls for the object\n"
  @"  mcl-logn <object>        -- Start logging method calls for the object using its name\n"
  @"  mcl-unlog <object>       -- Stop logging method calls for the object\n"
  @"  mcl-unlog-all            -- Stop logging method calls for all objects\n"
  @"  mcl-list                 -- List logged objects\n"
  @"  mcl-methods <object>     -- List methods for the object\n"
  @"  mcl-methods-all <object> -- List methods for the object and its ancestors\n"
  @"  mcl-help                 -- Show this help message\n";

  KKLog(@"%@", helpString);
}

+ (NSArray *)loggedObjects
{
  return [[self mutableLoggedObjects] copy];
}

+ (NSMutableArray *)mutableLoggedObjects
{
  static NSMutableArray *mutableLoggedObjects;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    mutableLoggedObjects = [NSMutableArray array];
  });

  return mutableLoggedObjects;
}

#pragma mark - Log Function

+ (void)setLogFunction:(void (*)(NSString *__strong, ...))logFunction
{
  KKSetLogFunction(logFunction);
}

+ (void)setLogFunctionToDefault
{
  KKSetLogFunctionToDefault();
}

+ (void (*)(NSString *__strong, ...))logFunction
{
  return KKLog;
}

@end
