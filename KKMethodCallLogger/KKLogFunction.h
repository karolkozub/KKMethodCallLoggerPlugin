//
//  KKLogFunction.h
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import <Foundation/Foundation.h>


extern void (*KKLog)(NSString *, ...);
extern void KKSetLogFunction(void (*)(NSString *, ...));
extern void KKSetLogFunctionToDefault();
