//
//  CALayer+StoryboardExtension.m
//  BibleTong
//
//  Created by mtjddnr on 2015. 9. 10..
//  Copyright © 2015년 iclab. All rights reserved.
//

#import "CALayer+StoryboardExtension.h"

@implementation CALayer (StoryboardExtension)
- (void)setBorderUIColor:(UIColor *)borderUIColor {
    self.borderColor = borderUIColor.CGColor;
}
- (UIColor *)borderUIColor {
    return [UIColor colorWithCGColor:self.borderColor];
}
- (void)setBackgroundUIColor:(UIColor *)backgroundUIColor {
    self.backgroundColor = backgroundUIColor.CGColor;
}
- (UIColor *)backgroundUIColor {
    return [UIColor colorWithCGColor:self.backgroundColor];
}
- (void)setShadowUIColor:(UIColor *)shadowUIColor {
    self.shadowColor = shadowUIColor.CGColor;
}
- (UIColor *)shadowUIColor {
    return [UIColor colorWithCGColor:self.shadowColor];
}
@end
