//
//  ActionRequestHandler.m
//  ContentBlocker
//
//  Created by MoonSung Wook on 2015. 8. 25..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "ActionRequestHandler.h"

@interface ActionRequestHandler ()
@property (strong, readonly) NSURL *blockerListPath;
@property (strong, readonly) NSURL *whiteListPath;
@property (strong, readonly) NSURL *path;
@end

@implementation ActionRequestHandler
- (NSURL *)blockerListPath {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json"];
}
- (NSURL *)whiteListPath {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"whiteList.json"];
}
- (NSURL *)path {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"output.json"];
}

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    [self buildList];
    
    NSItemProvider *attachment = [[NSItemProvider alloc] initWithContentsOfURL:self.path];
    NSExtensionItem *item = [[NSExtensionItem alloc] init];
    item.attachments = @[attachment];
    
    [context completeRequestReturningItems:@[item] completionHandler:nil];
}

- (void)buildList {
    NSURL *jsonPath = self.blockerListPath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[jsonPath path]] == NO) {
        jsonPath = [[NSBundle mainBundle] URLForResource:@"blockerList" withExtension:@"json"];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.whiteListPath path]] == NO) {
        [[NSFileManager defaultManager] copyItemAtURL:jsonPath toURL:self.path error:nil];
        return;
    }
    
    NSMutableArray *list = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:jsonPath]
                                                           options:NSJSONReadingMutableContainers
                                                             error:nil];
    [self injectWhiteList:list];
    
    NSError *err;
    NSData *output = [NSJSONSerialization dataWithJSONObject:list options:0 error:&err];
    [output writeToURL:self.path atomically:NO];
}

- (void)injectWhiteList:(NSMutableArray *)list {
    NSArray *whiteList = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:self.whiteListPath]
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    if ([whiteList count] == 0) return;
    
    [list enumerateObjectsUsingBlock:^(NSMutableDictionary *item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *trigger = item[@"trigger"];
        if (trigger == nil) return;
        NSMutableArray *unless = trigger[@"unless-domain"];
        NSMutableSet *set = [NSMutableSet setWithArray:whiteList];
        if (unless) [set addObjectsFromArray:unless];
        trigger[@"unless-domain"] = [set allObjects];
    }];
}
@end
