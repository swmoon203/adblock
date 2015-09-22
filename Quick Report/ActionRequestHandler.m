//
//  ActionRequestHandler.m
//  Quick Report
//
//  Created by mtjddnr on 2015. 9. 18..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "ActionRequestHandler.h"
#import <MobileCoreServices/MobileCoreServices.h>

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
    if (javaScriptPreprocessingResults[@"url"] == nil) return [self doneWithResults:nil];
    
    NSURL *jsonPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json"];
    NSDate *jsonDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[jsonPath path] error:nil] fileModificationDate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://adblock.smoon.kr/report"]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    
    NSDictionary *param = @{
                            @"url": javaScriptPreprocessingResults[@"url"],
                            @"type": @"QUICK",
                            @"memo": @"",
                            @"version": @([jsonDate timeIntervalSince1970])
                            };
    NSData *data = [NSJSONSerialization dataWithJSONObject:param options:kNilOptions error:NULL];
    [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self doneWithResults:@{ @"message" : @"AdBlocK에 알렸습니다." }];
    }] resume];
    
    
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
