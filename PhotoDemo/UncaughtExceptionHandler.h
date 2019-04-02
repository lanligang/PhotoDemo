//
//  UncaughtExceptionHandler.h
//  PhotoDemo
//
//  Created by ios2 on 2019/3/5.
//  Copyright © 2019 ShanZhou. All rights reserved.
//http://www.sharejs.com/codes/objectc/5882

#import <Foundation/Foundation.h>

@interface UncaughtExceptionHandler : NSObject{
	BOOL dismissed;
}
@end
void HandleException(NSException *exception);
void SignalHandler(int signal);


void InstallUncaughtExceptionHandler(void);

