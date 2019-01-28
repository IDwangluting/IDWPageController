//
//  WWPageViewController.m
//  WWPageController
//
//  Created by luting on 07/11/2016.
//  Copyright © 2016 WWPageController. All rights reserved.
//

#import "WWPageViewController.h"
#import "UIView+Frame.h"
#import "WWPageMenu.h"

const void *_SCROLLVIEW_OFFSET = &_SCROLLVIEW_OFFSET;

@interface WWPageViewController () <UIScrollViewDelegate, WWPageMenuDelegate>

@property (nonatomic, strong) NSCache *offscreenCache;
@property (nonatomic, strong) NSMutableSet *onScreen;

@property (nonatomic, strong) NSLayoutConstraint *menuHeightConstraint;
@property (nonatomic, weak) UIViewController *currentDisplayController;
@property (nonatomic) CGFloat menuHeight;
//默认当前预加载数量：左+右，default 1
@property (nonatomic) NSInteger preloadCnt;
@property (nonatomic) CGFloat menuPostionY;

@end

@implementation WWPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
}

- (void)dealloc {
    [self removeObseverForPageController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.offscreenCache removeAllObjects];
}

- (void)commonInit {
    self.offscreenCache = [[NSCache alloc] init];
    self.offscreenCache.countLimit = 10;
    self.onScreen = [NSMutableSet setWithCapacity:4];
    self.preloadCnt = 1;
    self.minimumTopInset = 0.0;
}

- (void)_addScrollView {
    if (_scrollView)  return;
    
    UIScrollView *scrollView = [self scrollView];
    [self.view addSubview:scrollView];
    
    NSArray *gestureArray = self.navigationController.view.gestureRecognizers;
    //当是侧滑手势的时候设置scrollview需要此手势失效才生效即可
    for (UIGestureRecognizer *gesture in gestureArray) {
        if ([gesture isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]){
            [scrollView.panGestureRecognizer requireGestureRecognizerToFail:gesture];
        }
    }
    
    [self.view
     addConstraint:[NSLayoutConstraint constraintWithItem:self.menu
                                                attribute:NSLayoutAttributeLeft
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.view
                                                attribute:NSLayoutAttributeLeft
                                               multiplier:1
                                                 constant:0]];
    [self.view
     addConstraint:[NSLayoutConstraint constraintWithItem:self.menu
                                                attribute:NSLayoutAttributeTop
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.view
                                                attribute:NSLayoutAttributeTop
                                               multiplier:1
                                                 constant:self.menuPostionY]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:self.menu
                              attribute:NSLayoutAttributeRight
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view
                              attribute:NSLayoutAttributeRight
                              multiplier:1
                              constant:0]];
}

- (void)_addPageMenu {
    if ([self.delegate respondsToSelector:@selector(pageMenu:)]) {
        [_menu removeFromSuperview];
        _menu = nil;
        _menu = [self.delegate pageMenu:self];
        if (self.menu) {
            [self.view addSubview:self.menu];
            [self configureMenuLayout];
        }
    }
}

- (void)configureMenuLayout {
    CGFloat navigationHeight;
    if (!self.navigationController.navigationBar.hidden) {
        navigationHeight = 0.0;
    }else{
        navigationHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    }
    self.menu.frame = CGRectMake(0, self.startPointY, self.view.frame.size.width, self.menu.height);
    self.menu.delegate = self;
    self.menuPostionY = self.menu.frame.origin.y;
    self.menuHeight = self.menu.height;
    
    [self.menu layoutMenus];
    
    self.menu.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuHeightConstraint =  [NSLayoutConstraint constraintWithItem:self.menu
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:0
                                                             multiplier:1
                                                               constant:self.menu.height];
    [self.menu addConstraint:self.menuHeightConstraint];
}

- (void)addObserverForPageController {
    if (self.minimumTopInset >= self.menuHeight || self.minimumTopInset < 0.01) {
        return;
    }
    UIScrollView *scrollView = [self _isKindOfScrollViewController:self.currentDisplayController];
    if (scrollView != nil) {
        [scrollView addObserver:self
                     forKeyPath:NSStringFromSelector(@selector(contentOffset))
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context:&_SCROLLVIEW_OFFSET];
    }
}

- (void)removeObseverForPageController {
    if (self.minimumTopInset >= self.menuHeight || self.minimumTopInset < 0.01) {
        return;
    }
    UIScrollView *scrollView = [self _isKindOfScrollViewController:self.currentDisplayController];
    if (scrollView != nil) {
        @try {
            [scrollView
             removeObserver:self
             forKeyPath:NSStringFromSelector(@selector(contentOffset))];
        } @catch (NSException *exception) {
            NSLog(@"exception is %@", exception);
        } @finally {}
    }
}

- (UIScrollView *)_isKindOfScrollViewController:(UIViewController *)controller {
    UIScrollView *scrollView = nil;
    if ([controller.view isKindOfClass:[UIScrollView class]]) {
        scrollView = (UIScrollView *)controller.view;
    } else if (controller.view.subviews.count >= 1) {
        UIView *view = controller.view.subviews[0];
        if ([view isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)view;
        }
    }
    return scrollView;
}

- (UIScrollView *)scrollView {
    if (_scrollView)  return _scrollView;
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.delegate = self;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.scrollEnabled = YES;
    _scrollView = scrollView;
    return scrollView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self _layoutScrollViewSubviews];
}

- (void)_layoutScrollViewSubviews {
    CGFloat navigationHeight;
    if (self.isCustomTopBar) {
        navigationHeight = 64;
    }else{
        navigationHeight = 0;
    }
    self.menu.frame = CGRectMake(0, navigationHeight, self.view.frame.size.width, self.menu.height);
    CGRect scrollFrame = CGRectMake(0, self.menu.bottom, self.view.width, self.view.height - self.menu.bottom );
    self.scrollView.frame = scrollFrame;
    NSInteger pageCount = [self.delegate numberOfPages:self];
    self.scrollView.contentSize = CGSizeMake(pageCount * self.view.width, 0);
    
//    CGRect scrollFrame = CGRectMake(0, self.menuHeightConstraint.constant + self.menuPostionY, self.view.width, self.view.height - self.menuHeightConstraint.constant);
//    self.scrollView.frame = scrollFrame;
//    NSInteger pageCount = [self.delegate numberOfPages:self];
//    self.scrollView.contentSize = CGSizeMake(pageCount * self.view.width, 0);
//    
//    self.menu.frame = CGRectMake(0, self.startPointY, self.view.frame.size.width, self.menu.height);
}

- (CGFloat)tabBarHeight {
    if (!self.tabBarController.tabBar || self.hidesBottomBarWhenPushed || self.tabBarController.tabBar.hidden) {
        return 0.0f;
    }
    return CGRectGetHeight(self.tabBarController.tabBar.frame);
}

- (void)reloadData {
    [self clearData];
    
    [self _addPageMenu];
    [self _addScrollView];
    [self _layoutScrollViewSubviews];
    [self _addChildControllerAtIndex:self.selectedIndex];
    [self _addObserverForCurrActiveController];
    [self.menu slideMenuAtIndex:self.selectedIndex];
    CGPoint targetP = CGPointMake(self.view.width * self.selectedIndex, 0);
    [self.scrollView setContentOffset:targetP animated:NO];
    
    NSArray *gestureArray = self.navigationController.view.gestureRecognizers;
    //当是侧滑手势的时候设置scrollview需要此手势失效才生效即可
    for (UIGestureRecognizer *gesture in gestureArray) {
        if ([gesture isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]){
            [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:gesture];
        }
    }
}

- (void)clearData {
    [self commonInit];
    
    [_menu removeFromSuperview];
    _menu = nil;
    
    [_scrollView removeFromSuperview];
    _scrollView = nil;
    __block WWPageViewController *weakSelf = self;
    [self.onScreen enumerateObjectsUsingBlock:^(NSNumber *  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            NSInteger index = [obj integerValue];
            UIViewController *vc = [weakSelf.offscreenCache objectForKey:@(index)];
            [weakSelf _removeChildController:vc];
        }
    }];
    
    [self.offscreenCache removeAllObjects];
    [self.onScreen removeAllObjects];
}

#pragma mark - |
- (void)_addChildController:(UIViewController *)controller {
    if (!controller)  return;
    
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
    [self.scrollView addSubview:controller.view];
}

- (void)_addChildControllerAtIndex:(NSInteger)index {
    UIViewController *vc = [self dequeueViewControllerWithIdentifier:nil atIndex:index];
    if (!vc)  return;
    
    if (![self.onScreen containsObject:@(index)]) {
        [self addChildViewController:vc];
        [self.scrollView addSubview:vc.view];
        [vc didMoveToParentViewController:self];
        [self.onScreen addObject:@(index)];
    }
    vc.view.frame = CGRectMake(index * self.view.width, 0, self.view.width, self.scrollView.height);
}

- (void)_removeUnsedControllerAtIndex:(NSInteger)index controller:(UIViewController *)controller {
    if (!controller)  return;
    
    [self _removeChildController:controller];
    [self.onScreen removeObject:@(index)];
}

- (void)_removeUnsedControllers {
    [self.onScreen enumerateObjectsUsingBlock:^(NSNumber *  _Nonnull number, BOOL * _Nonnull stop) {
        if ([number isKindOfClass:[NSNumber class]]) {
            NSInteger index = [number integerValue];
            UIViewController *controller = [self.offscreenCache objectForKey:@(index)];
            if (controller && [self _isOutBoundsForIndex:index]) {
                [self _removeUnsedControllerAtIndex:index controller:controller];
            }
        }
    }];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedIndex != selectedIndex) {
        [self removeObseverForPageController];
        _selectedIndex = selectedIndex;
        [self _addObserverForCurrActiveController];
    }
}

- (void)_addObserverForCurrActiveController {
    self.currentDisplayController = [self dequeueViewControllerWithIdentifier:nil atIndex:self.selectedIndex];
    [self addObserverForPageController];
}

- (BOOL)_isOutBoundsForIndex:(NSInteger)index {
    if (index > self.selectedIndex + self.preloadCnt || index < self.selectedIndex - self.preloadCnt) {
        return YES;
    }
    return NO;
}

- (void)_removeChildController:(UIViewController *)controller {
    if (!controller)  return ;
    
    [controller.view removeFromSuperview];
    [controller willMoveToParentViewController:nil];
    [controller removeFromParentViewController];
    [controller didMoveToParentViewController:nil];
}

- (UIViewController *)dequeueViewControllerWithIdentifier:(NSString *)identifier atIndex:(NSInteger)index {
    UIViewController * vc = [self.offscreenCache objectForKey:@(index)];
    if (vc) return vc;
    
    if ([self.delegate respondsToSelector:@selector(pageControllerForIndex:)]){
        vc = [self.delegate pageControllerForIndex:index];
        if (vc) [self.offscreenCache setObject:vc forKey:@(index)];
    }
    return vc;
}

- (void)_updateControllers {
    NSInteger lowIndex = MAX(0, self.selectedIndex - self.preloadCnt);
    NSInteger maxIndex = [self.delegate numberOfPages:self];
    NSInteger highIndex = MIN(maxIndex - 1, self.selectedIndex + self.preloadCnt);
    for (NSInteger index = lowIndex; index <= highIndex; index++) {
        [self _addChildControllerAtIndex:index];
    }
}

- (NSInteger)newPageIndex {
    NSInteger maxIndex = [self.delegate numberOfPages:self];
    CGRect visibleBounds = _scrollView.bounds;
    NSInteger newPageIndex = MIN(MAX(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)), 0), maxIndex - 1);
    
    newPageIndex = MAX(0, MIN(maxIndex, newPageIndex));
    return newPageIndex;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollView != scrollView)  return;
    
    NSInteger currIndex = [self newPageIndex];
    if (currIndex == self.selectedIndex)  return;
    
    self.selectedIndex = currIndex;
    [self _updateControllers];
    if (scrollView.isDragging) {
        [self.menu slideMenuAtIndex:self.selectedIndex animation:YES];
    }
    
    if (scrollView.contentOffset.y == 0)  return;
    
    CGPoint contentOffset = scrollView.contentOffset;
    contentOffset.y = 0.0;
    scrollView.contentOffset = contentOffset;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.scrollView != scrollView)  return;
    
    self.menu.userInteractionEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.scrollView != scrollView)  return;
    
    self.menu.userInteractionEnabled = YES;
    [self _removeUnsedControllers];
    if ([self.delegate respondsToSelector:@selector(pageController:didSlideAtindex:)]) {
        [self.delegate pageController:self didSlideAtindex:self.selectedIndex];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.scrollView != scrollView)  return;
    
    self.menu.userInteractionEnabled = YES;
    [self _removeUnsedControllers];
    //[self _addObserverForCurrActiveController];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.menu.userInteractionEnabled = YES;
        NSInteger currIndex = self.scrollView.contentOffset.x / self.view.width;
        [self.menu slideMenuAtIndex:currIndex animation:YES];
    }
}

#pragma mark - WWPageMenuDelegate
- (void)slideMenuAtIndex:(NSInteger)index {
    //
}

- (void)pageMenu:(WWPageMenu *)menu didSelesctedIndex:(NSInteger)index {
    CGPoint targetP = CGPointMake(self.view.width * index, 0);
    [self.scrollView setContentOffset:targetP animated:NO];
    if ([self.delegate respondsToSelector:@selector(pageController:didSelectedAtindex:)]) {
        [self.delegate pageController:self didSelectedAtindex:index];
    }
    //[self _addObserverForCurrActiveController];
}

- (NSInteger)numberOfMenu:(WWPageMenu *)menu {
    if ([self.delegate respondsToSelector:@selector(numberOfPages:)]) {
        return [self.delegate numberOfPages:self];
    }
    return 0;
}

- (NSString *)pageMenu:(WWPageMenu *)menu titleAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(pageController:titleForPageIndex:)]) {
        return [self.delegate pageController:self titleForPageIndex:index];
    }
    return nil;
}

- (UIColor *)pageMenu:(WWPageMenu *)menu colorAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(pageController:colorAtIndex:)]) {
        return [self.delegate pageController:self colorAtIndex:index];
    }
    return nil;
}

#pragma mark -
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(UIScrollView *)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == _SCROLLVIEW_OFFSET) {
        
        CGPoint offset = [change[NSKeyValueChangeNewKey] CGPointValue];
        CGFloat offsetY = offset.y;
        CGPoint oldOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
        CGFloat oldOffsetY = oldOffset.y;
        CGFloat deltaOfOffsetY = offset.y - oldOffsetY;
        //不能滑动的不需要处理
        if (object.height >= object.contentSize.height)  return;
        
        if (oldOffset.y <= 0.0f && offset.y <= 0.0f)  return;
        
        if (deltaOfOffsetY >= 0 && offsetY>=0.0) {
            //向上滑动如果 大于inset时候也不需要处理
            if (offsetY >= self.minimumTopInset && self.menuHeightConstraint.constant >= self.menuHeight) {
                return;
            }
            if (self.menuHeightConstraint.constant - deltaOfOffsetY <= 0) {
                self.menuHeightConstraint.constant = self.minimumTopInset;
                return;
            } else {
                self.menuHeightConstraint.constant -= deltaOfOffsetY;
            }
            if (self.menuHeightConstraint.constant <= self.minimumTopInset) {
                self.menuHeightConstraint.constant = self.minimumTopInset;
            }
            if (offsetY >= self.minimumTopInset && self.menuHeightConstraint.constant != self.minimumTopInset) {
                self.menuHeightConstraint.constant = self.minimumTopInset;
            }
            
        } else {
            //对于向下滑动时 如果已经到达最小的inset 不需要处理
            if (offsetY >= self.minimumTopInset && self.menuHeightConstraint.constant <= self.minimumTopInset) {
                return;
            }
            if (offsetY > 0) {
                if (self.menuHeightConstraint.constant < self.menuHeight) {
                    self.menuHeightConstraint.constant -= deltaOfOffsetY;
                } else {
                    self.menuHeightConstraint.constant = self.menuHeight;
                }
                
                if (self.menuHeightConstraint.constant <= self.minimumTopInset) {
                    self.menuHeightConstraint.constant = self.minimumTopInset;
                }
            } else {
                self.menuHeightConstraint.constant = self.menuHeight;
            }
        }
    }
}

- (void)willMoveToParentViewController:(UIViewController*)parent{
    [super willMoveToParentViewController:parent];
    self.scrollView.scrollEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.scrollView.scrollEnabled = YES;
}

@end
