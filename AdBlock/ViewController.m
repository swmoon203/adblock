//
//  ViewController.m
//  AdBlock
//
//  Created by MoonSung Wook on 2015. 8. 25..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "ViewController.h"
#import <SafariServices/SafariServices.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *jsonPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[jsonPath path]];
    
    NSLog(@"%@", jsonPath);
    NSLog(@"%i", exists);
    
    if (exists == NO) {
        NSURL *source = [[NSBundle mainBundle] URLForResource:@"blockerList" withExtension:@"json"];
        NSLog(@"%@", source);
        NSError *err = nil;
        [[NSFileManager defaultManager] copyItemAtURL:source toURL:jsonPath error:&err];
        NSLog(@"%@", err);
    }
    
    [SFContentBlockerManager reloadContentBlockerWithIdentifier:@"kr.smoon.AdBlock.ContentBlocker"
                                              completionHandler:^(NSError * _Nullable error) {
                                                  NSLog(@"%@", error);
    }];
    
    
}

@end
