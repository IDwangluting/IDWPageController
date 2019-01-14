//
//  WWPageMenu.h
//  WWPageController
//
//  Created by luting on 07/11/2016.
//  Copyright © 2016 WWPageController. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WWPageMenu;

@protocol WWPageMenuDelegate <NSObject>

@required

- (NSInteger)numberOfMenu:(WWPageMenu *)menu;
- (NSString *)pageMenu:(WWPageMenu *)menu titleAtIndex:(NSInteger)index;
//滑动menu
- (void)slideMenuAtIndex:(NSInteger)index;
//点击menu
- (void)pageMenu:(WWPageMenu *)menu didSelesctedIndex:(NSInteger)index;
- (UIColor *)pageMenu:(WWPageMenu *)menu colorAtIndex:(NSInteger)index;

@optional

@end

@interface WWPageMenu : UIView <WWPageMenuDelegate>

@property (nonatomic, weak) id<WWPageMenuDelegate>delegate;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *selectedColor;

//menu 左右两边的间距 默认10
@property (nonatomic, assign) CGFloat leading;
//menu的最小宽度default40
@property (nonatomic, assign) CGFloat minimumWidth;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *bottomViewBGColor;
@property (nonatomic, assign) CGFloat bottomViewHeight;
@property (nonatomic, assign) CGFloat btmViewChangeHeight;

@property (nonatomic, assign) CGFloat lineHeight;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *bottomLineColor;


//滑动到某个menu
- (void)slideMenuAtIndex:(NSInteger)index;
- (void)slideMenuAtIndex:(NSInteger)index animation:(BOOL)animation;

//只有调用layoutMenus 才会布局
- (void)layoutMenus;

@end
