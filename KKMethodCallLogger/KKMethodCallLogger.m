//
//  KKMethodCallLogger.m
//  KKMethodCallLogger
//
//  Created by Karol Kozub on 2014-12-28.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import "KKMethodCallLogger.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>


static void KKDefaultLog(NSString *, ...);


static const char kObjectOriginalClassKey;
static const char kObjectProxyClassKey;
static const char kObjectNameKey;
static void (*sLogFunction)(NSString *, ...) = KKDefaultLog;


@interface KKMethodCallLoggerProxyClassManager : NSObject

+ (Class)proxyClassForClass:(Class)klass;

@end


@implementation KKMethodCallLogger

+ (void)startLoggingMethodCallsForObject:(id)object
{
  [self startLoggingMethodCallsForObject:object withName:nil];
}

+ (void)startLoggingMethodCallsForObject:(id)object withName:(NSString *)name
{
  if (object == nil) {
    sLogFunction(@"KKMethodCallLogger cannot log calls for a nil object.");
    return;
  }

  if (class_isMetaClass(object_getClass(object))) {
    sLogFunction(@"KKMethodCallLogger doesn't currently support logging class method calls.");
    return;
  }

  Class proxyClass = [KKMethodCallLoggerProxyClassManager proxyClassForClass:[object class]];

  if (objc_getAssociatedObject(object, &kObjectProxyClassKey) != proxyClass) {
    objc_setAssociatedObject(object, &kObjectOriginalClassKey, [object class], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(object, &kObjectProxyClassKey,    proxyClass,     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    object_setClass(object, proxyClass);

    [[self mutableLoggedObjects] addObject:object];
  }

  objc_setAssociatedObject(object, &kObjectNameKey, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)stopLoggingMethodCallsForObject:(id)object
{
  Class objectClass = objc_getAssociatedObject(object, &kObjectOriginalClassKey);
  Class proxyClass  = [KKMethodCallLoggerProxyClassManager proxyClassForClass:objectClass];

  if (objc_getAssociatedObject(object, &kObjectProxyClassKey) == proxyClass) {
    object_setClass(object, objectClass);
    objc_setAssociatedObject(object, &kObjectNameKey,       nil,         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(object, &kObjectProxyClassKey, objectClass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

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

  sLogFunction(@"%@", methodListString);
}

+ (void)listLoggedObjects
{
  NSMutableString *objectListString = [NSMutableString string];

  for (id object in [self mutableLoggedObjects]) {
    NSString *objectName = objc_getAssociatedObject(object, &kObjectNameKey);
    [objectListString appendFormat:@"<%@: %p>%@%@\n", NSStringFromClass([object class]), object, objectName ? @" ": @"", objectName ?: @""];
  }

  sLogFunction(@"%@", objectListString);
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

  sLogFunction(@"%@", helpString);
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
  sLogFunction = logFunction;
}

+ (void)setDefaultLogFunction
{
  sLogFunction = KKDefaultLog;
}

+ (void (*)(NSString *__strong, ...))logFunction
{
  return sLogFunction;
}

@end


@interface NSInvocation (PrivateAPI)

- (void)invokeUsingIMP:(IMP)imp;

@end


static void KKDefaultLog(NSString *format, ...)
{
  va_list arguments;
  va_start(arguments, format);

  NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
  printf("%s\n", [message cStringUsingEncoding:NSUTF8StringEncoding]);

  va_end(arguments);
}


@implementation KKMethodCallLoggerProxyClassManager

+ (Class)proxyClassForClass:(Class)klass
{
  NSString *proxyClassName = [NSString stringWithFormat:@"KKMethodCallLoggerProxyClassFor%@", NSStringFromClass(klass)];
  Class proxySuperclass = [self proxySuperclassForClass:class_getSuperclass(klass)];
  Class proxyClass;

  if ((proxyClass = NSClassFromString(proxyClassName))) {
    return proxyClass;
  }

  proxyClass = objc_allocateClassPair(proxySuperclass, [proxyClassName UTF8String], 0);

  [self copyMethodFromClass:self                  toClass:proxyClass                  withFromSelector:@selector(proxyForwardInvocation:) toSelector:@selector(forwardInvocation:)];
  [self copyMethodFromClass:self                  toClass:proxyClass                  withFromSelector:@selector(proxyClass)              toSelector:@selector(class)];
  [self copyMethodFromClass:self                  toClass:proxyClass                  withFromSelector:@selector(proxySuperclass)         toSelector:@selector(superclass)];
  [self copyMethodFromClass:object_getClass(self) toClass:object_getClass(proxyClass) withFromSelector:@selector(emptyInitialize)         toSelector:@selector(initialize)];

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

  [self copyMethodFromClass:self                  toClass:proxySuperclass                  withFromSelector:@selector(superproxyForwardInvocation:) toSelector:@selector(forwardInvocation:)];
  [self copyMethodFromClass:self                  toClass:proxySuperclass                  withFromSelector:@selector(superproxyClass)              toSelector:@selector(class)];
  [self copyMethodFromClass:self                  toClass:proxySuperclass                  withFromSelector:@selector(proxySuperclass)              toSelector:@selector(superclass)];
  [self copyMethodFromClass:object_getClass(self) toClass:object_getClass(proxySuperclass) withFromSelector:@selector(emptyInitialize)              toSelector:@selector(initialize)];

  for (NSString *selectorName in [self basicInstanceSelectorNamesDirectlyContainedInClass:klass]) {
    SEL selector = NSSelectorFromString(selectorName);
    [self copyMethodFromClass:klass toClass:proxySuperclass withFromSelector:selector toSelector:selector];
  }

  objc_registerClassPair(proxySuperclass);

  return proxySuperclass;
}

+ (void)copyMethodFromClass:(Class)fromClass toClass:(Class)toClass withFromSelector:(SEL)fromSelector toSelector:(SEL)toSelector
{
  Method method = class_getInstanceMethod(fromClass, fromSelector);
  IMP imp = method_getImplementation(method);
  const char *typeEncoding = method_getTypeEncoding(method);

  class_addMethod(toClass, toSelector, imp, typeEncoding);
}

- (void)proxyForwardInvocation:(NSInvocation *)invocation
{
  NSString *objectName   = objc_getAssociatedObject(self, &kObjectNameKey) ?: NSStringFromClass([self class]);
  NSString *selectorName = NSStringFromSelector(invocation.selector);
  Class originalClass = objc_getAssociatedObject(self, &kObjectOriginalClassKey);
  Class proxyClass    = objc_getAssociatedObject(self, &kObjectProxyClassKey);

  sLogFunction(@"-[%@ %@]", objectName, selectorName);

  object_setClass(self, originalClass);
  [invocation invokeWithTarget:self];
  object_setClass(self, proxyClass);
}

- (void)superproxyForwardInvocation:(NSInvocation *)invocation
{
  Class originalClass = objc_getAssociatedObject(self, &kObjectOriginalClassKey);
  Class proxyClass    = objc_getAssociatedObject(self, &kObjectProxyClassKey);
  Class superclass    = class_getSuperclass(originalClass);
  Method superMethod = class_getInstanceMethod(superclass, _cmd);
  IMP superImp = method_getImplementation(superMethod);

  object_setClass(self, originalClass);
  [invocation invokeUsingIMP:superImp];
  object_setClass(self, proxyClass);
}

- (Class)proxyClass
{
  return NSClassFromString([NSStringFromClass(object_getClass(self)) substringFromIndex:[@"KKMethodCallLoggerProxyClassFor" length]]);
}

- (Class)superproxyClass
{
  return NSClassFromString([NSStringFromClass(object_getClass(self)) substringFromIndex:[@"KKMethodCallLoggerProxySuperclassFor" length]]);
}

- (Class)proxySuperclass
{
  return class_getSuperclass([self class]);
}

+ (void)emptyInitialize
{
}

+ (NSSet *)basicInstanceSelectorNames
{
  static NSSet *basicInstanceSelectorNames;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    basicInstanceSelectorNames = [NSSet setWithArray:@[@"isEqual:", @"hash", @"self", @"isKindOfClass:", @"isMemberOfClass:", @"respondsToSelector:", @"conformsToProtocol:", @"methodSignatureForSelector:", @"description", @"debugDescription", @"performSelector:", @"doesNotRecognizeSelector:", @"performSelector:withObject:", @"performSelector:withObject:withObject:", @"isProxy", @"retain", @"release", @"autorelease", @"retainCount", @"zone", @"dealloc", @"finalize"]];
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

+ (BOOL)classIsBaseClass:(Class)klass
{
  return klass == [NSObject class] || klass == [NSProxy class];
}

@end