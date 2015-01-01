//
//  KKLLDBCommandInjector.h
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2014-12-31.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KKLLDBCommandInjector : NSObject

@property (nonatomic, copy) NSString *dylibPath;

+ (instancetype)sharedInstance;
- (void)start;
- (void)stop;

@end
