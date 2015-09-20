//
//  ActionRequestHandler.m
//  Whitelist
//
//  Created by MoonSung Wook on 2015. 9. 20..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "ActionRequestHandler.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <SafariServices/SafariServices.h>

@interface ActionRequestHandler ()

@property (nonatomic, strong) NSExtensionContext *extensionContext;

@end

@implementation ActionRequestHandler

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    self.extensionContext = context;
    
    BOOL found = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *dictionary, NSError *error) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self itemLoadCompletedWithPreprocessingResults:dictionary[NSExtensionJavaScriptPreprocessingResultsKey]];
                    }];
                }];
                found = YES;
            }
            break;
        }
        if (found) break;
    }
    
    if (!found) [self doneWithResults:nil];
}

- (void)itemLoadCompletedWithPreprocessingResults:(NSDictionary *)javaScriptPreprocessingResults {
    NSLog(@"%@", javaScriptPreprocessingResults);
    NSURL *path = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"whiteList.json"];
    NSData *data = [NSData dataWithContentsOfURL:path];
    NSMutableArray *list = nil;
    if (data == nil) {
        list = [NSMutableArray array];
    } else {
        list  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    }
    NSString *domain = javaScriptPreprocessingResults[@"domain"];
    if ([list containsObject:domain]) return [self doneWithResults:@{}];
    [list addObject:domain];
    
    data = [NSJSONSerialization dataWithJSONObject:list options:0 error:nil];
    [data writeToURL:path atomically:NO];
    
    [SFContentBlockerManager reloadContentBlockerWithIdentifier:@"kr.smoon.AdBlock.ContentBlocker"
                                              completionHandler:^(NSError * _Nullable error) {
                                                  NSLog(@"%@", error);
                                                  [self doneWithResults:@{}];
                                              }];
}


- (void)doneWithResults:(NSDictionary *)resultsForJavaScriptFinalize {
    if (resultsForJavaScriptFinalize) {
        NSDictionary *resultsDictionary = @{ NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize };
        
        NSItemProvider *resultsProvider = [[NSItemProvider alloc] initWithItem:resultsDictionary typeIdentifier:(NSString *)kUTTypePropertyList];
        
        NSExtensionItem *resultsItem = [[NSExtensionItem alloc] init];
        resultsItem.attachments = @[resultsProvider];
        
        [self.extensionContext completeRequestReturningItems:@[resultsItem] completionHandler:nil];
    } else {
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }
    self.extensionContext = nil;
}

@end
