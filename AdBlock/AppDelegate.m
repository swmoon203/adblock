//
//  AppDelegate.m
//  AdBlock
//
//  Created by MoonSung Wook on 2015. 8. 25..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "AppDelegate.h"
#import <SafariServices/SafariServices.h>

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
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self synciTunesFile];
    [self setupiTunesDocumentWatcher];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    dispatch_source_cancel(_source);
    _source = nil;
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
    NSString *status = [date descriptionWithLocale:[NSLocale currentLocale]];
    [[NSUserDefaults standardUserDefaults] setObject:status forKey:StatusKey];
    return status;
}
- (NSString *)status {
    NSString *status = [[NSUserDefaults standardUserDefaults] stringForKey:StatusKey];
    if (status == nil) {
        NSFileManager *fs = [NSFileManager defaultManager];
        NSDate *jsonDate = [[fs attributesOfItemAtPath:[self.jsonPath path] error:nil] fileModificationDate];
        status = [self setStatusWithDate:jsonDate];
    }
    return status;
}

#pragma mark -
- (void)setupiTunesDocumentWatcher {
    NSString *homeDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    int filedes = open([homeDirectory cStringUsingEncoding:NSASCIIStringEncoding], O_EVTONLY);
    
    if (_dispatchQueue == nil) _dispatchQueue = dispatch_queue_create("FileMonitorQueue", 0);
    
    // Write covers - adding a file, renaming a file and deleting a file...
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,filedes,
                                     DISPATCH_VNODE_WRITE,
                                     _dispatchQueue);
    
    
    // This block will be called when teh file changes
    dispatch_source_set_event_handler(_source, ^(){
        [[NSNotificationCenter defaultCenter] postNotificationName:iTunesUpdatedNotification object:Nil];
    });
    
    // When we stop monitoring the file this will be called and it will close the file descriptor
    dispatch_source_set_cancel_handler(_source, ^() {
        close(filedes);
    });
    
    // Start monitoring the file...
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
            break;
        case NSOrderedDescending: //itune file is newer
            //if ([self validateJSON:self.iTunesJsonPath] == NO) return;
            [fs removeItemAtURL:self.jsonPath error:nil];
            [fs copyItemAtURL:self.iTunesJsonPath toURL:self.jsonPath error:nil];
            [self updateSafariContentBlocker];
            break;
        case NSOrderedAscending:
            [fs removeItemAtURL:self.iTunesJsonPath error:nil];
            [fs copyItemAtURL:self.jsonPath toURL:self.iTunesJsonPath error:nil];
            break;
    }
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
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:UpdatedNotification object:nil];                                                  
                                              }];
}
@end
