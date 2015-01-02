//
//  NSInvocation+PrivateAPI.h
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSInvocation (PrivateAPI)

- (void)invokeUsingIMP:(IMP)imp;

@end
