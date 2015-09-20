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
        MainTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if (cell != nil) {
            cell.lblCount.text = [@(self.app.itemCount) stringValue];
            cell.lblTime.text = self.app.status;
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self.tableView reloadData];
    }];
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
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
    return section == 0 ? nil : [self.app.whitelist count] > 0 ? @"Whitelist" : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : [self.app.whitelist count];
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"main" forIndexPath:indexPath];
            cell.lblCount.text = [@(self.app.itemCount) stringValue];
            cell.lblTime.text = self.app.status;
            cell.imgAutoupdate.hidden = !self.app.autoUpdate;
            return cell;
        }
        case 1: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"white" forIndexPath:indexPath];
            cell.textLabel.text = self.app.whitelist[indexPath.row];
            return cell;
        }
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES; //indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.app removeWhitelistAtIndexe:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if ([self.app.whitelist count] == 0) {
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewRowAction *on = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                      title:@"Auto Update On"
                                                                    handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                        MainTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                                                                        cell.imgAutoupdate.hidden = NO;
                                                                        self.app.autoUpdate = YES;
                                                                        [self.tableView setEditing:NO animated:YES];
                                                                    }];
        on.backgroundColor = [UIColor colorWithRed:(19.0/255.0) green:(12.0/255.0) blue:(75.0/255.0) alpha:1.0];
        UITableViewRowAction *off = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                       title:@"Auto Update Off"
                                                                     handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                         MainTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                                                                         cell.imgAutoupdate.hidden = YES;
                                                                         self.app.autoUpdate = NO;
                                                                         [self.tableView setEditing:NO animated:YES];
                                                                     }];
        
        return self.app.autoUpdate ? @[ off ] : @[ on ];
    } else {
        return nil;
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
