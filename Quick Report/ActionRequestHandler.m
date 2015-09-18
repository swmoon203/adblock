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
                                  NSLog(@"%@", urlString);
                              }];
    }
}
@end
