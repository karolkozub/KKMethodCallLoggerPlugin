//
//  KKMethodCallLoggerPlugin.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2014-12-28.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import "KKMethodCallLoggerPlugin.h"
#import "KKLLDBCommandInjector.h"
#import "KKXcodeRuntime.h"


@implementation KKMethodCallLoggerPlugin

+ (void)pluginDidLoad:(NSBundle *)bundle
{
  NSString *dylibPath = [bundle pathForResource:@"libKKMethodCallLogger" ofType:@"dylib"];

  if (dylibPath == nil) {
    NSLog(@"KKMethodCallLoggerPlugin failed to load. libKKMethodCallLogger.dylib is missing from the bundle.");
    return;
  }

  if (![self xcodeRuntimeSupportsRequiredMethods]) {
    NSLog(@"KKMethodCallLoggerPlugin failed to load. Xcode runtime doesn't support its required methods.");
    return;
  }

  [[KKLLDBCommandInjector sharedInstance] setDylibPath:dylibPath];
  [[KKLLDBCommandInjector sharedInstance] start];
}

+ (BOOL)xcodeRuntimeSupportsRequiredMethods
{
  return [NSClassFromString(@"DBGLLDBLauncher") instancesRespondToSelector:@selector(_executeLLDBCommands:)] &&
         [NSClassFromString(@"DBGProcess")      instancesRespondToSelector:@selector(isPaused)]              &&
         [NSClassFromString(@"DBGLLDBSession")  instancesRespondToSelector:@selector(pauseRequested)]        &&
         [NSClassFromString(@"DBGLLDBSession")  instancesRespondToSelector:@selector(setPauseRequested:)]    &&
         [NSClassFromString(@"DBGLLDBSession")  instancesRespondToSelector:@selector(launcher)]              &&
         [NSClassFromString(@"DBGLLDBSession")  instancesRespondToSelector:@selector(process)];
}

@end
