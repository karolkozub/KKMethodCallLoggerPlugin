//
//  KKLLDBCommandInjector.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2014-12-31.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import "KKLLDBCommandInjector.h"
#import "KKXcodeRuntime.h"
#import "KKSwizzler.h"


@interface KKLLDBCommandInjector ()

@property (nonatomic, getter=isRunning) BOOL running;
@property (nonatomic, weak) DBGLLDBSession *lastInjectedSession;

@end


@implementation KKLLDBCommandInjector

+ (instancetype)sharedInstance
{
  static typeof([self new]) sharedInstance;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [self new];
  });

  return sharedInstance;
}

- (void)start
{
  self.running = YES;
}

- (void)stop
{
  self.running = NO;
}

#pragma mark - API for DBGLLDBSession

- (void)handleSessionDidPause:(DBGLLDBSession *)session
{
  __weak typeof(self) weakSelf = self;

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    if ([[session process] isPaused] && weakSelf.isRunning && weakSelf.lastInjectedSession != session) {
      [[session launcher] _executeLLDBCommands:[NSString stringWithFormat:@"expr (void)dlopen(\"%@\", 0x2);\n", weakSelf.dylibPath]];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-log "
                                               @"'s/(.+)/expr [KKMethodCallLogger startLoggingMethodCallsForObject:(id)%1];/' "
                                               @"-h 'Start logging method calls for the object.' \n"];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-logn "
                                               @"'s/(.+)/expr [KKMethodCallLogger startLoggingMethodCallsForObject:(id)%1 withName:@\"%1\"];/' "
                                               @"-h 'Start logging method calls for the object with its name.' \n"];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-unlog "
                                               @"'s/(.+)/expr [KKMethodCallLogger stopLoggingMethodCallsForObject:(id)%1];/' "
                                               @"-h 'Stop logging method calls for the object.' \n"];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-unlog-all "
                                               @"'s/(.*)/expr [KKMethodCallLogger stopLoggingMethodCallsForAllObjects];/' "
                                               @"-h 'Stop logging method calls for all objects.' \n"];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-list "
                                               @"'s/(.*)/expr [KKMethodCallLogger listLoggedObjects];/' "
                                               @"-h 'List logged objects.' \n"];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-methods "
                                               @"'s/(.+)/expr [KKMethodCallLogger listMethodsForObject:(id)%1];/' "
                                               @"-h 'List methods for the object.' \n"];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-methods-all "
                                               @"'s/(.+)/expr [KKMethodCallLogger listMethodsForObject:(id)%1 includingAncestors:YES];/' "
                                               @"-h 'List methods for the object including ancestors.' \n"];
      [[session launcher] _executeLLDBCommands:@"command regex mcl-help "
                                               @"'s/(.*)/expr [KKMethodCallLogger showHelpMessage];/' "
                                               @"-h 'Show a help message.' \n"];
      [[session launcher] _executeLLDBCommands:@"po @\"KKMethodCallLogger loaded.\"\n"];
      weakSelf.lastInjectedSession = session;
    }
  });
}

@end


@implementation KKSwizzler (DBGLLDBSession)

+ (void)load
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self swizzle:@selector(DBGLLDBSession$setPauseRequested:)];
  });
}

- (void)DBGLLDBSession$setPauseRequested:(BOOL)pauseRequested
{
  [self DBGLLDBSession$setPauseRequested:pauseRequested];

  BOOL pauseIsNoLongerRequested = !pauseRequested;

  if (pauseIsNoLongerRequested) {
    [[KKLLDBCommandInjector sharedInstance] handleSessionDidPause:(id)self];
  }
}

@end
