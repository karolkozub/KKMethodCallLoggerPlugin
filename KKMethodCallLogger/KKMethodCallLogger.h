//
//  KKMethodCallLogger.h
//  KKMethodCallLogger
//
//  Created by Karol Kozub on 2014-12-28.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KKMethodCallLogger : NSObject

+ (void)startLoggingMethodCallsForObject:(id)object;
+ (void)startLoggingMethodCallsForObject:(id)object withName:(NSString *)name;
+ (void)stopLoggingMethodCallsForObject:(id)object;
+ (void)stopLoggingMethodCallsForAllObjects;
+ (void)listMethodsForClass:(Class)klass;
+ (void)listMethodsForClass:(Class)klass includingAncestors:(BOOL)includingAncestors;
+ (void)listLoggedObjects;

+ (NSArray *)loggedObjects;

+ (void)setLogFunction:(void (*)(NSString *, ...))logFunction;
+ (void)setLogFunctionToDefault;
+ (void (*)(NSString *, ...))logFunction;

@end
