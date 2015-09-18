//
//  ActionViewController.m
//  Report
//
//  Created by mtjddnr on 2015. 9. 17..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ActionViewController ()
@property (strong) NSString *url;
@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = item.attachments.firstObject;
    if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"]) {
        [itemProvider loadItemForTypeIdentifier:@"public.url"
                                        options:nil
                              completionHandler:^(NSURL *url, NSError *error) {
                                  NSString *urlString = url.absoluteString;
                                  self.url = urlString;
                              }];
    }
    
}

- (IBAction)cancel {
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
