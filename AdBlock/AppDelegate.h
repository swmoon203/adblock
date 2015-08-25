//
//  AppDelegate.h
//  AdBlock
//
//  Created by MoonSung Wook on 2015. 8. 25..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const UpdateURLKey;
UIKIT_EXTERN NSString *const AutoUpdateKey;
UIKIT_EXTERN NSString *const StatusKey;
UIKIT_EXTERN NSString *const UpdatedNotification;
UIKIT_EXTERN NSString *const iTunesUpdatedNotification;


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, readonly) NSURL *bundleJsonPath;
@property (strong, readonly) NSURL *jsonPath;
@property (strong, readonly) NSURL *iTunesJsonPath;

- (void)updateSafariContentBlocker;

@property (strong, readonly) NSString *status;

@property (strong, nonatomic) NSURL *updateURL;
@property (readonly, nonatomic) NSInteger itemCount;

- (void)downloadAndUpdate:(void (^)(void))completionHandler;
@end

