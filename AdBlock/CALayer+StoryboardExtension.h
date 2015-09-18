//
//  CALayer+StoryboardExtension.h
//  BibleTong
//
//  Created by mtjddnr on 2015. 9. 10..
//  Copyright © 2015년 iclab. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface CALayer (StoryboardExtension)
@property (strong, nonatomic) UIColor *borderUIColor; //borderColor
@property (strong, nonatomic) UIColor *backgroundUIColor; //backgroundColor
@property (strong, nonatomic) UIColor *shadowUIColor; //shadowColor
@end
