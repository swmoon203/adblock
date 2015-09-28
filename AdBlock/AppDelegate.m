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
NSString *const UpdatedNotification = @"UpdatedNotification";
NSString *const iTunesUpdatedNotification = @"iTunesUpdatedNotification";

@interface AppDelegate()
@property (strong, nonatomic, readonly) NSURL *jsonPathBackup;
@property (strong, nonatomic, readonly) NSURL *whitelistJsonPath;
@end
@implementation AppDelegate {
    dispatch_queue_t _dispatchQueue;
    dispatch_source_t _source;
    NSMutableArray *_whitelist;
}
@synthesize whitelist=_whitelist;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [self synciTunesFile];
    [self setupiTunesDocumentWatcher];
    [[NSNotificationCenter defaultCenter] addObserverForName:iTunesUpdatedNotification object:Nil queue:Nil usingBlock:^(NSNotification * notification) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(synciTunesFile) withObject:nil afterDelay:0.5];
        });
    }];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:AutoUpdateKey] == nil) self.autoUpdate = YES;
    
    if (self.autoUpdate) {
        [self downloadAndUpdate:^{}];
    }
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self synciTunesFile];
    [self setupiTunesDocumentWatcher];
    _whitelist = nil;
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
- (NSURL *)jsonPathBackup {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json.backup"];
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
    return [date timeAgo];
}
- (NSString *)status {
    NSFileManager *fs = [NSFileManager defaultManager];
    NSDate *jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
    return [self setStatusWithDate:jsonDate];
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
    
    //if ([fs fileExistsAtPath:[self.iTunesJsonPath path]] == NO) [fs copyItemAtURL:self.bundleJsonPath toURL:self.iTunesJsonPath error:nil];
    //if ([fs fileExistsAtPath:[self.jsonPath path]] == NO) [fs copyItemAtURL:self.iTunesJsonPath toURL:self.jsonPath error:nil];
    if ([fs fileExistsAtPath:[self.jsonPath path]] == NO) [fs copyItemAtURL:self.bundleJsonPath toURL:self.jsonPath error:nil];
    
    //NSDate *itunesDate = [[fs attributesOfItemAtPath:[self.iTunesJsonPath path] error:nil] fileModificationDate];
    NSDate *jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
    
//    switch ([itunesDate compare:jsonDate]) {
//        case NSOrderedSame: //not changed
//            [self updateCount];
//            return;
//        case NSOrderedDescending: //itune file is newer
//            [fs removeItemAtURL:self.jsonPath error:nil];
//            [fs copyItemAtURL:self.iTunesJsonPath toURL:self.jsonPath error:nil];
//            break;
//        case NSOrderedAscending:
//            [fs removeItemAtURL:self.iTunesJsonPath error:nil];
//            [fs copyItemAtURL:self.jsonPath toURL:self.iTunesJsonPath error:nil];
//            break;
//    }
    [self updateCount];
    [self updateSafariContentBlocker];
    
    jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
    [self setStatusWithDate:jsonDate];
}

- (void)downloadAndUpdate:(void (^)(void))completionHandler {
   [[[NSURLSession sharedSession] dataTaskWithURL:self.updateURL
                               completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                   if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                       [[NSFileManager defaultManager] moveItemAtURL:self.jsonPath toURL:self.jsonPathBackup error:nil];
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
                                                  NSFileManager *fs = [NSFileManager defaultManager];
                                                  if (error == nil || error.userInfo[NSHelpAnchorErrorKey] == nil) {
                                                      [fs removeItemAtURL:self.jsonPathBackup error:nil];
                                                      NSDate *jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
                                                      [self setStatusWithDate:jsonDate];
                                                  } else {
                                                      NSLog(@"%@", error.userInfo[NSHelpAnchorErrorKey]);
                                                      [fs removeItemAtURL:self.jsonPath error:nil];
                                                      [fs moveItemAtURL:self.jsonPathBackup toURL:self.jsonPath error:nil];
                                                      [self updateSafariContentBlocker];
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

#pragma mark - Whitelist
- (NSURL *)whitelistJsonPath {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"whiteList.json"];
}
- (NSArray *)whitelist {
    if (_whitelist == nil) {
        NSData *data = [NSData dataWithContentsOfURL:self.whitelistJsonPath];
        if (data == nil) return nil;
        _whitelist = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    }
    return _whitelist;
}
- (void)removeWhitelistAtIndexe:(NSUInteger)index {
    [_whitelist removeObjectAtIndex:index];
    NSData *data = [NSJSONSerialization dataWithJSONObject:_whitelist options:0 error:nil];
    [data writeToURL:self.whitelistJsonPath atomically:NO];
    [self updateSafariContentBlocker];
}
@end
