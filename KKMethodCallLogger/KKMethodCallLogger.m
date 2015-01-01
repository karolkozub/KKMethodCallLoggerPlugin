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


@interface KKMethodCallLoggerProxy : NSProxy
@end


@implementation KKMethodCallLogger

+ (void)startLoggingMethodCallsForObject:(id)object
{
  [self startLoggingMethodCallsForObject:object withName:nil];
}

+ (void)startLoggingMethodCallsForObject:(id)object withName:(NSString *)name
{
  if (class_isMetaClass(object_getClass(object))) {
    sLogFunction(@"KKMethodCallLogger doesn't support logging class method calls.");
    return;
  }

  if ([object retainCount] == NSUIntegerMax) {
    sLogFunction(@"KKMethodCallLogger doesn't support logging objects with infinite retain count.");
    return;
  }

  if (objc_getAssociatedObject(object, &kObjectProxyClassKey) != [KKMethodCallLoggerProxy class]) {
    objc_setAssociatedObject(object, &kObjectOriginalClassKey, [object class],               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(object, &kObjectProxyClassKey, [KKMethodCallLoggerProxy class], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    object_setClass(object, [KKMethodCallLoggerProxy class]);

    [[self loggedObjectPointers] addPointer:object];
  }
  
  objc_setAssociatedObject(object, &kObjectNameKey, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)stopLoggingMethodCallsForObject:(id)object
{
  Class objectClass = objc_getAssociatedObject(object, &kObjectOriginalClassKey);

  if (objc_getAssociatedObject(object, &kObjectProxyClassKey) == [KKMethodCallLoggerProxy class]) {
    object_setClass(object, objectClass);
    objc_setAssociatedObject(object, &kObjectNameKey,  nil,              OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(object, &kObjectProxyClassKey, objectClass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    for (NSInteger i = 0; i < [[self loggedObjectPointers] count]; i++) {
      if ([[self loggedObjectPointers] pointerAtIndex:i] == object) {
        [[self loggedObjectPointers] removePointerAtIndex:i];
        break;
      }
    }
  }
}

+ (void)stopLoggingMethodCallsForAllObjects
{
  [[self loggedObjectPointers] compact];

  for (NSInteger i = [[self loggedObjectPointers] count] - 1; i >= 0; i--) {
    id object = [[self loggedObjectPointers] pointerAtIndex:i];

    if (object) {
      [self stopLoggingMethodCallsForObject:object];

    } else {
      [[self loggedObjectPointers] removePointerAtIndex:i];
    }
  }
}

+ (void)listMethodsForObject:(id)object
{
  [self listMethodsForObject:object includingAncestors:NO];
}

+ (void)listMethodsForObject:(id)object includingAncestors:(BOOL)includingAncestors
{
  NSMutableString *methodListString = [NSMutableString string];

  for (Class class = [object class]; class; class = includingAncestors ? [class superclass] : nil) {
    [methodListString appendFormat:@"%@\n", NSStringFromClass(class)];
    unsigned int methodCount;
    Method *methods = class_copyMethodList(class, &methodCount);
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

  for (NSInteger i = 0; i < [[self loggedObjectPointers] count]; i++) {
    id object = [[self loggedObjectPointers] pointerAtIndex:i];

    if (object) {
      NSString *objectName = objc_getAssociatedObject(object, &kObjectNameKey);
      [objectListString appendFormat:@"<%@: %p>%@%@\n", NSStringFromClass([object class]), object, objectName ? @" ": @"", objectName ?: @""];

    } else {
      [[self loggedObjectPointers] removePointerAtIndex:i];
      i--;
    }
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
  return [[self loggedObjectPointers] allObjects];
}

+ (NSPointerArray *)loggedObjectPointers
{
  static NSPointerArray *loggedObjectPointers;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    loggedObjectPointers = [[NSPointerArray weakObjectsPointerArray] retain];
  });

  return loggedObjectPointers;
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


#pragma mark - KKMethodCallLoggerProxy

@implementation KKMethodCallLoggerProxy

- (Class)class
{
  return objc_getAssociatedObject(self, &kObjectOriginalClassKey);
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  NSString *objectName   = objc_getAssociatedObject(self, &kObjectNameKey) ?: NSStringFromClass([self class]);
  NSString *selectorName = NSStringFromSelector(invocation.selector);
  sLogFunction(@"-[%@ %@]", objectName, selectorName);

  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  [invocation invokeWithTarget:self];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return methodSignature;
}

- (BOOL)respondsToSelector:(SEL)selector
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  BOOL respondsToSelector = [self respondsToSelector:selector];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return respondsToSelector;
}

- (BOOL)isEqual:(id)object
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  BOOL isEqual = [self isEqual:object];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return isEqual;
}

- (NSUInteger)hash
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  NSUInteger hash = [self hash];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return hash;
}

- (NSString *)description
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  NSString *description = [self description];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return description;
}

- (NSString *)debugDescription
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  NSString *debugDescription = [self debugDescription];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return debugDescription;
}

- (NSUInteger)retainCount
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  NSUInteger retainCount = [self retainCount];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return retainCount;
}

- (oneway void)release
{
  BOOL isLastRelease = [self retainCount] < 2;

  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  [self release];

  if (!isLastRelease) {
    object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));
  }
}

- (instancetype)autorelease
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  id autoreleased = [self autorelease];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return autoreleased;
}

- (BOOL)isProxy
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  BOOL isProxy = [self isProxy];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return isProxy;
}

- (struct _NSZone *)zone
{
  object_setClass(self, objc_getAssociatedObject(self, &kObjectOriginalClassKey));
  struct _NSZone * zone = [self zone];
  object_setClass(self, objc_getAssociatedObject(self, &kObjectProxyClassKey));

  return zone;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)dealloc
{
  [KKMethodCallLogger stopLoggingMethodCallsForObject:self];
  [self dealloc];
}
#pragma clang diagnostic pop

@end


static void KKDefaultLog(NSString *format, ...)
{
  va_list arguments;
  va_start(arguments, format);

  NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
  printf("%s\n", [message cStringUsingEncoding:NSUTF8StringEncoding]);

  va_end(arguments);
}
