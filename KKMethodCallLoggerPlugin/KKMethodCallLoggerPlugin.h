//
//  KKMethodCallLoggerPlugin.h
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2014-12-28.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface KKMethodCallLoggerPlugin : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end