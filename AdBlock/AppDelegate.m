//
//  AppDelegate.m
//  AdBlock
//
//  Created by MoonSung Wook on 2015. 8. 25..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "AppDelegate.h"
#import <SafariServices/SafariServices.h>
#import "NSDate+TimeAgo.h"

NSString *const UpdateURLKey = @"UpdateURL";
NSString *const AutoUpdateKey = @"AutoUpdate";
NSString *const StatusKey = @"Status";
NSString *const UpdatedNotification = @"UpdatedNotification";
NSString *const iTunesUpdatedNotification = @"iTunesUpdatedNotification";

@implementation AppDelegate {
    dispatch_queue_t _dispatchQueue;
    dispatch_source_t _source;
}
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [self synciTunesFile];
    [self setupiTunesDocumentWatcher];
    [[NSNotificationCenter defaultCenter] addObserverForName:iTunesUpdatedNotification object:Nil queue:Nil usingBlock:^(NSNotification * notification) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(synciTunesFile) withObject:nil afterDelay:0.5];
        });
    }];
    self.autoUpdate = YES;
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self synciTunesFile];
    [self setupiTunesDocumentWatcher];
    [[NSNotificationCenter defaultCenter] postNotificationName:UpdatedNotification object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    dispatch_source_cancel(_source);
    _source = nil;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self downloadAndUpdate:^{
        completionHandler(UIBackgroundFetchResultNewData);
    }];
}

#pragma mark -

- (NSURL *)bundleJsonPath {
    return [[NSBundle mainBundle] URLForResource:@"blockerList" withExtension:@"json"];
}
- (NSURL *)jsonPath {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json"];
}
- (NSURL *)iTunesJsonPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"blockerList.json"]];
}


- (BOOL)validateJSON:(NSURL *)path {
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:[NSData dataWithContentsOfURL:path]
                          options:kNilOptions
                          error:&error];
    NSLog(@"%@", error);
    NSLog(@"%@", json);
    return json != nil && error == nil;
}

- (NSString *)setStatusWithDate:(NSDate *)date {
    //NSString *status = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    NSString *status = [date timeAgo];
    [[NSUserDefaults standardUserDefaults] setObject:status forKey:StatusKey];
    return status;
}
- (NSString *)status {
    NSString *status = [[NSUserDefaults standardUserDefaults] stringForKey:StatusKey];
    NSFileManager *fs = [NSFileManager defaultManager];
    NSDate *jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
    status = [self setStatusWithDate:jsonDate];
    return status;
}

- (NSURL *)updateURL {
    NSURL *url = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:UpdateURLKey]];
    if (url == nil) {
        url = [NSURL URLWithString:@"https://raw.githubusercontent.com/swmoon203/adblock/blockerList.json/blockerList.json"];
        [[NSUserDefaults standardUserDefaults] setObject:[url absoluteString] forKey:UpdateURLKey];
    }
    return url;
}
- (void)setUpdateURL:(NSURL *)updateURL {
    [[NSUserDefaults standardUserDefaults] setObject:updateURL forKey:UpdateURLKey];
}
#pragma mark -
- (void)setupiTunesDocumentWatcher {
    NSString *homeDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    int filedes = open([homeDirectory cStringUsingEncoding:NSASCIIStringEncoding], O_EVTONLY);
    
    if (_dispatchQueue == nil) _dispatchQueue = dispatch_queue_create("FileMonitorQueue", 0);
    
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, filedes, DISPATCH_VNODE_WRITE, _dispatchQueue);
    
    dispatch_source_set_event_handler(_source, ^(){
        [[NSNotificationCenter defaultCenter] postNotificationName:iTunesUpdatedNotification object:Nil];
    });
    
    dispatch_source_set_cancel_handler(_source, ^() {
        close(filedes);
    });
    
    dispatch_resume(_source);
}

- (void)synciTunesFile {
    NSFileManager *fs = [NSFileManager defaultManager];
    
    if ([fs fileExistsAtPath:[self.iTunesJsonPath path]] == NO) [fs copyItemAtURL:self.bundleJsonPath toURL:self.iTunesJsonPath error:nil];
    if ([fs fileExistsAtPath:[self.jsonPath path]] == NO) [fs copyItemAtURL:self.iTunesJsonPath toURL:self.jsonPath error:nil];
    
    NSDate *itunesDate = [[fs attributesOfItemAtPath:[self.iTunesJsonPath path] error:nil] fileModificationDate];
    NSDate *jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
    
    switch ([itunesDate compare:jsonDate]) {
        case NSOrderedSame: //not changed
            [self updateCount];
            return;
        case NSOrderedDescending: //itune file is newer
            [fs removeItemAtURL:self.jsonPath error:nil];
            [fs copyItemAtURL:self.iTunesJsonPath toURL:self.jsonPath error:nil];
            break;
        case NSOrderedAscending:
            [fs removeItemAtURL:self.iTunesJsonPath error:nil];
            [fs copyItemAtURL:self.jsonPath toURL:self.iTunesJsonPath error:nil];
            break;
    }
    [self updateCount];
    [self updateSafariContentBlocker];
    
    jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
    [self setStatusWithDate:jsonDate];
}

- (void)downloadAndUpdate:(void (^)(void))completionHandler {
   [[[NSURLSession sharedSession] dataTaskWithURL:self.updateURL
                               completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                   NSLog(@"%@", [(NSHTTPURLResponse *)response allHeaderFields]);
                                   if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                       [data writeToURL:self.jsonPath atomically:NO];
                                       [self synciTunesFile];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                          [[NSNotificationCenter defaultCenter] postNotificationName:UpdatedNotification object:nil];
                                       });
                                   }
                                   
                                   dispatch_async(dispatch_get_main_queue(), completionHandler);
                               }] resume];
   
}

- (void)updateSafariContentBlocker {
    [SFContentBlockerManager reloadContentBlockerWithIdentifier:@"kr.smoon.AdBlock.ContentBlocker"
                                              completionHandler:^(NSError * _Nullable error) {
                                                  if (error == nil) {
                                                      NSFileManager *fs = [NSFileManager defaultManager];
                                                      NSDate *jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
                                                      [self setStatusWithDate:jsonDate];
                                                  } else {
                                                      [[NSUserDefaults standardUserDefaults] setObject:error.userInfo[NSHelpAnchorErrorKey] forKey:StatusKey];
                                                  }
                                                  [self updateCount];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:UpdatedNotification object:nil];                                                  
                                              }];
}

- (void)updateCount {
    NSArray *list = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:self.jsonPath]
                                                    options:NSJSONReadingAllowFragments
                                                      error:nil];
    _itemCount = [list count];
}

- (void)setAutoUpdate:(BOOL)autoUpdate {
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:autoUpdate ? UIApplicationBackgroundFetchIntervalMinimum : UIApplicationBackgroundFetchIntervalNever];
    [[NSUserDefaults standardUserDefaults] setBool:autoUpdate forKey:AutoUpdateKey];
}
- (BOOL)autoUpdate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:AutoUpdateKey];
}
@end
