//
//  AppDelegate.m
//  PaymentViaWebDemo
//
//  Created by Ze Shao on 2020/7/21.
//  Copyright © 2020 Ze Shao. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    RootViewController *rootVC = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:[NSBundle mainBundle]];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    return YES;
}





@end
