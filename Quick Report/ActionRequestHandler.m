//
//  ActionRequestHandler.m
//  Quick Report
//
//  Created by mtjddnr on 2015. 9. 18..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "ActionRequestHandler.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ActionRequestHandler

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    NSExtensionItem *item = context.inputItems.firstObject;
    NSItemProvider *itemProvider = item.attachments.firstObject;
    if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"]) {
        [itemProvider loadItemForTypeIdentifier:@"public.url"
                                        options:nil
                              completionHandler:^(NSURL *url, NSError *error) {
                                  NSString *urlString = url.absoluteString;
                                  
                                  NSURL *jsonPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.AdBlock"] URLByAppendingPathComponent:@"blockerList.json"];
                                  NSDate *jsonDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[jsonPath path] error:nil] fileModificationDate];
                                  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://adblock.smoon.kr/report"]];
                                  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                                  request.HTTPMethod = @"POST";
                                  
                                  NSDictionary *param = @{
                                                          @"url": urlString,
                                                          @"type": @"QUICK",
                                                          @"memo": @"",
                                                          @"version": @([jsonDate timeIntervalSince1970])
                                                          };
                                  NSData *data = [NSJSONSerialization dataWithJSONObject:param options:kNilOptions error:NULL];
                                  [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:data] resume];
                                  
                              }];
    }
}
@end
