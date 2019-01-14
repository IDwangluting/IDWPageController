//
//  WWPageMenuLabel.m
//  WWPageController
//
//  Created by luting on 07/11/2016.
//  Copyright © 2016 WWPageController. All rights reserved.
//

#import "WWPageMenuLabel.h"

@implementation WWPageMenuLabel

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.label = [[UILabel alloc] init];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (void)selected {
    self.isSelected = YES;
    self.label.textColor = self.selectedColor;
}

- (void)unselected {
    self.isSelected = NO;
    self.label.textColor = self.normalColor;
}

- (void)setText:(NSString *)text {
    self.label.text = text;
}

- (void)updateColor {
    if (self.isSelected) {
        [self selected];
    } else {
        [self unselected];
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self.label sizeThatFits:size];
}

@end
