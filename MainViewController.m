//
//  MainViewController.m
//  AdBlock
//
//  Created by MoonSung Wook on 2015. 8. 25..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"

@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UILabel *updated;
@property (weak, nonatomic) IBOutlet UILabel *itemCount;
@property (weak, nonatomic) IBOutlet UITextField *updateURL;
@property (weak, nonatomic) IBOutlet UISwitch *autoUpdate;

@property (weak, readonly) AppDelegate *app;
@end

@implementation MainViewController {
    BOOL _working;
}

- (AppDelegate *)app {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.updated.text = self.app.status;
    self.itemCount.text = [@(self.app.itemCount) stringValue];
    self.updateURL.text = [self.app.updateURL absoluteString];
    self.autoUpdate.on = self.app.autoUpdate;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserverForName:UpdatedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        self.itemCount.text = [@(self.app.itemCount) stringValue];
        self.updated.text = self.app.status;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:@"update"]) {
        if (_working) return;
        _working = YES;
        
        cell.textLabel.text = @"Loading...";
        [self.app downloadAndUpdate:^{
            _working = NO;
            cell.textLabel.text = @"Update";
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (IBAction)onAutoUpdate:(id)sender {
    self.app.autoUpdate = self.autoUpdate.on;
}

@end
