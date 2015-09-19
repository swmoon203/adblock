//
//  RootTableViewController.m
//  AdBlock
//
//  Created by MoonSung Wook on 2015. 9. 19..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "RootTableViewController.h"
#import "MainTableViewCell.h"
#import "AppDelegate.h"
#import "CBStoreHouseRefreshControl.h"

@interface RootTableViewController ()

@property (weak, readonly) AppDelegate *app;
@property (nonatomic, strong) CBStoreHouseRefreshControl *storeHouseRefreshControl;
@end

@implementation RootTableViewController {
    BOOL _working;
}

- (AppDelegate *)app {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = self.view.frame.size.height;
    self.storeHouseRefreshControl = [CBStoreHouseRefreshControl attachToScrollView:self.tableView
                                                                            target:self
                                                                     refreshAction:@selector(refreshTriggered:)
                                                                             plist:@"loading"
                                                                             color:[UIColor whiteColor]
                                                                         lineWidth:1.5
                                                                        dropHeight:80
                                                                             scale:1
                                                              horizontalRandomness:150
                                                           reverseLoadingAnimation:YES
                                                           internalAnimationFactor:0.5];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserverForName:UpdatedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        //[self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
        MainTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if (cell != nil) {
            cell.lblCount.text = [@(self.app.itemCount) stringValue];
            cell.lblTime.text = self.app.status;
        }
    }];
    
}
#pragma mark - Notifying refresh control of scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.storeHouseRefreshControl scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.storeHouseRefreshControl scrollViewDidEndDragging];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? nil : nil; //@"Whitelist";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"main" forIndexPath:indexPath];
            cell.lblCount.text = [@(self.app.itemCount) stringValue];
            cell.lblTime.text = self.app.status;
            return cell;
        }
        case 1: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"white" forIndexPath:indexPath];
            
            return cell;
        }
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark -
- (void)refreshTriggered:(id)sender {
    //[self performSelector:@selector(finishRefreshControl) withObject:nil afterDelay:3 inModes:@[NSRunLoopCommonModes]];

    if (_working) return;
    _working = YES;
    [self.app downloadAndUpdate:^{
        _working = NO;
        [self performSelector:@selector(finishRefreshControl) withObject:nil afterDelay:0.5 inModes:@[NSRunLoopCommonModes]];
    }];
}
- (void)finishRefreshControl {
    [self.storeHouseRefreshControl finishingLoading];
}
@end
