//
//  KKAssociatedObjects.h
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import <Foundation/Foundation.h>


extern Class KKAssociatedProxyClass(id object);
extern NSString *KKAssociatedName(id object);
extern void KKSetAssociatedProxyClass(id object, Class klass);
extern void KKSetAssociatedName(id object, NSString *name);
