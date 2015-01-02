//
//  KKLogFunction.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2015-01-02.
//  Copyright (c) 2015 Karol Kozub. All rights reserved.
//

#import "KKLogFunction.h"


static void KKDefaultLog(NSString *, ...);
void (*KKLog)(NSString *, ...) = KKDefaultLog;


void KKSetLogFunction(void (*function)(NSString *, ...))
{
  KKLog = function;
}

void KKSetLogFunctionToDefault()
{
  KKSetLogFunction(KKDefaultLog);
}

void KKDefaultLog(NSString *format, ...)
{
  va_list arguments;
  va_start(arguments, format);

  NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
  printf("%s\n", [message cStringUsingEncoding:NSUTF8StringEncoding]);

  va_end(arguments);
}
