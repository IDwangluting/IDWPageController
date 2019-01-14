//
//  WWPageViewController.h
//  WWPageController
//
//  Created by luting on 07/11/2016.
//  Copyright © 2016 WWPageController. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WWPageViewController;
@class WWPageMenu;

@protocol WWPageViewControllerDelegate <NSObject>

@required

- (NSInteger)numberOfPages:(WWPageViewController *)controller;
- (UIViewController *)pageControllerForIndex:(NSInteger)index;
- (NSString *)pageController:(WWPageViewController *)controller titleForPageIndex:(NSInteger)index;
- (WWPageMenu *)pageMenu:(WWPageViewController *)controller;
- (UIColor *)pageController:(WWPageViewController *)controller colorAtIndex:(NSInteger)index;

@optional

- (void)pageController:(WWPageViewController *)controller didSelectedAtindex:(NSInteger)index;
- (void)pageController:(WWPageViewController *)controller didSlideAtindex:(NSInteger)index;

@end

@interface WWPageViewController : UIViewController

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, weak) id<WWPageViewControllerDelegate>delegate;
//you can only modify height
@property (nonatomic, readonly) WWPageMenu *menu;
@property(nonatomic) BOOL isCustomTopBar;
@property(nonatomic) CGFloat startPointY;
//default 0
@property (nonatomic) NSInteger selectedIndex;

//default 0.0 won't change headerview height
@property(nonatomic) CGFloat minimumTopInset;

- (void)reloadData;

@end
