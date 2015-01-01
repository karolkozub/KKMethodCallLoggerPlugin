//
//  KKXcodeRuntime.h
//  KKHighlightRecentPlugin
//
//  Created by Karol Kozub on 2014-11-09.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IDERunOperationWorker : NSObject
@end


@interface IDERunOperationPathWorker : IDERunOperationWorker
@end


@interface DBGLLDBLauncher : IDERunOperationPathWorker

- (void)_executeLLDBCommands:(NSString *)commands;

@end


@interface DBGProcess : NSObject

- (BOOL)isPaused;

@end


@interface DBGDebugSession : NSObject
@end


@interface DBGLLDBSession : DBGDebugSession

@property BOOL pauseRequested;
@property (readonly) DBGLLDBLauncher *launcher;
@property (readonly) DBGProcess *process;

@end
