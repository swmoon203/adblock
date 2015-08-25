//
//  ActionRequestHandler.m
//  ContentBlocker
//
//  Created by MoonSung Wook on 2015. 8. 25..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "ActionRequestHandler.h"

@interface ActionRequestHandler ()

@end

@implementation ActionRequestHandler

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    
    NSURL *jsonPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[jsonPath path]] == NO) {
        jsonPath = [[NSBundle mainBundle] URLForResource:@"blockerList" withExtension:@"json"];
    }
    
    NSItemProvider *attachment = [[NSItemProvider alloc] initWithContentsOfURL:jsonPath];
    NSExtensionItem *item = [[NSExtensionItem alloc] init];
    item.attachments = @[attachment];
    
    [context completeRequestReturningItems:@[item] completionHandler:nil];
}

@end
