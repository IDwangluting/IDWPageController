//
//  WWPageMenuItem.m
//  Pods
//
//  Created by luting on 16/11/2016.
//
//

#import "WWPageMenuItem.h"

@implementation WWPageMenuItem

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)setNormalColor:(UIColor *)normalColor {
    _normalColor = normalColor;
    [self updateColor];
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    _selectedColor = selectedColor;
    [self updateColor];
}

- (void)updateColor {
    if (self.isSelected) {
        [self selected];
    } else {
        [self unselected];
    }
}

- (void)setText:(NSString *)text {
    
}


- (void)selected {
    
}

- (void)unselected {
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(didClickedMenuLabel:)]) {
        [self.delegate didClickedMenuLabel:self];
    }
}

@end
