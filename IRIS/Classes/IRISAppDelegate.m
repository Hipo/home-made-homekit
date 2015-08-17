//
//  IRISAppDelegate.m
//  IRIS
//
//  Created by Taylan Pince on 2015-08-17.
//  Copyright (c) 2015 Hipo. All rights reserved.
//

#import "IRISAppDelegate.h"
#import "IRISRootViewController.h"


@interface IRISAppDelegate ()

@end


@implementation IRISAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    IRISRootViewController *viewController = [[IRISRootViewController alloc] init];

    [_window setRootViewController:viewController];
    [_window setBackgroundColor:[UIColor whiteColor]];
    [_window makeKeyAndVisible];
    
    return YES;
}

@end
