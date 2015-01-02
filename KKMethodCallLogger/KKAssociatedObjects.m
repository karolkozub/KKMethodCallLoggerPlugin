//
//  KKAssociatedObjects.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import "KKAssociatedObjects.h"
#import <objc/runtime.h>


static const char kObjectOriginalClassKey;
static const char kObjectProxyClassKey;
static const char kObjectNameKey;


Class KKAssociatedOriginalClass(id object)
{
  return objc_getAssociatedObject(object, &kObjectOriginalClassKey);
}

Class KKAssociatedProxyClass(id object)
{
  return objc_getAssociatedObject(object, &kObjectProxyClassKey);
}

NSString *KKAssociatedName(id object)
{
  return objc_getAssociatedObject(object, &kObjectNameKey);
}

void KKSetAssociatedOriginalClass(id object, Class klass)
{
  objc_setAssociatedObject(object, &kObjectOriginalClassKey, klass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void KKSetAssociatedProxyClass(id object, Class klass)
{
  objc_setAssociatedObject(object, &kObjectProxyClassKey, klass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void KKSetAssociatedName(id object, NSString *name)
{
  objc_setAssociatedObject(object, &kObjectNameKey, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
