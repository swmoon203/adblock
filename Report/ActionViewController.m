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
@property (strong, nonatomic) IBOutlet UITextField *txtURL;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segOption;
@property (strong, nonatomic) IBOutlet UITextField *txtMemo;
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
                                  self.txtURL.text = urlString;
                              }];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.txtMemo becomeFirstResponder];
}

- (IBAction)cancel {
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}
- (IBAction)submit:(id)sender {
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    
    NSURL *jsonPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json"];
    NSDate *jsonDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[jsonPath path] error:nil] fileModificationDate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://adblock.smoon.kr/report"]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    
    
    NSArray *options = @[ @"NOT_BLOCKED", @"MALFUNCTION", @"ETC" ];
    NSDictionary *param = @{
                            @"url": self.txtURL.text,
                            @"type": options[self.segOption.selectedSegmentIndex],
                            @"memo": self.txtMemo.text == nil ? @"" : self.txtMemo.text,
                            @"version": @([jsonDate timeIntervalSince1970])
                            };
    NSData *data = [NSJSONSerialization dataWithJSONObject:param options:kNilOptions error:NULL];
    [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:data] resume];
}

@end
