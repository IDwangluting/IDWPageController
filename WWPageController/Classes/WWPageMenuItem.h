//
//  WWPageMenuItem.h
//  Pods
//
//  Created by luting on 16/11/2016.
//
//

#import <UIKit/UIKit.h>

@class WWPageMenuItem;

@protocol WWPageMenuItemDelegate <NSObject>

- (void)didClickedMenuLabel:(WWPageMenuItem *)label;

@end

@interface WWPageMenuItem : UIView

@property (nonatomic, weak) id<WWPageMenuItemDelegate>delegate;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) BOOL isSelected;

- (void)selected;
- (void)unselected;

@end
