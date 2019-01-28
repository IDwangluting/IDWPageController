//
//  WWPageLineMenu.m
//  WWPageController
//
//  Created by luting on 07/11/2016.
//  Copyright © 2016 WWPageController. All rights reserved.
//

#import "WWPageLineMenu.h"
#import "WWPageMenuItem.h"
#import "WWPageMenuLabel.h"
#import "UIView+frame.h"

@interface WWPageLineMenu () <WWPageMenuItemDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSArray *menuFrame;
@property (nonatomic, assign) CGFloat lineMargin;

@end

@implementation WWPageLineMenu

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        [self createBottomView];
    }
    return self;
}

- (void)commonInit {
    self.normalColor = [UIColor blackColor];
    self.selectedColor = [UIColor redColor];
    _selectedIndex = -1;
    self.font = [UIFont systemFontOfSize:16];
    self.minimumWidth = 40;
    self.leading = 10;
    self.lineHeight = 2.0;
    self.lineColor = [UIColor redColor];
    self.lineMargin = 6;
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.scrollView];
}

- (void)addIndicatorView {
    self.indicatorView = [[UIView alloc] initWithFrame:CGRectZero];
    self.indicatorView.backgroundColor = self.lineColor;
    self.bottomView.backgroundColor = self.bottomViewBGColor;
    [self.scrollView addSubview:self.indicatorView];
    
    CGRect firstMenuFrame = [[self.menuFrame firstObject] CGRectValue];
    WWPageMenuItem *label = [self.scrollView viewWithTag:1];
    if (label) {
        CGFloat positionX = firstMenuFrame.origin.x + label.width * 0.5 - firstMenuFrame.size.width * 0.5;
        self.indicatorView.frame = CGRectMake(positionX, self.scrollView.height - self.lineHeight,
                                              MIN(firstMenuFrame.size.width, label.width) ,self.lineHeight);
    }
}

-(void)createBottomView{
    UIView *bottomView = [[UIView alloc]init];
    bottomView.backgroundColor = [UIColor clearColor];
    self.bottomView = bottomView;
    [self addSubview:bottomView];
}

- (void)updateIndicatorView:(BOOL)animated {
    WWPageMenuItem *label = [self.scrollView viewWithTag:self.selectedIndex];
    CGRect toFrame = [self.menuFrame[_selectedIndex - 1] CGRectValue];
    CGFloat positionX = toFrame.origin.x + label.width * 0.5 - toFrame.size.width * 0.5;
    if (CGRectEqualToRect(self.indicatorView.frame, toFrame)) return;
    
    if (animated) {
        //TODO 优化动画时间
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            UIColor *color = self.lineColor;
            if ([self.delegate respondsToSelector:@selector(pageMenu:colorAtIndex:)]) {
                color = [self.delegate pageMenu:self colorAtIndex:self.selectedIndex - 1];
            }
            self.indicatorView.backgroundColor = color;
        } completion:nil];
    }
    self.indicatorView.frame = CGRectMake(positionX, self.scrollView.height - self.lineHeight, toFrame.size.width ,self.lineHeight);
}

- (void)layoutMenus {
    [self configureMenus];
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animation:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animation:(BOOL)animation {
    if (_selectedIndex == selectedIndex)  return;

    WWPageMenuItem *oldLabel = [self.scrollView viewWithTag:_selectedIndex];
    if ([oldLabel isKindOfClass:[WWPageMenuItem class]]) {
        [oldLabel  unselected];
    }
    WWPageMenuItem *label = [self.scrollView viewWithTag:selectedIndex];
    if ([label isKindOfClass:[WWPageMenuItem class]]) {
        [label  selected];
    }
    _selectedIndex = selectedIndex;
    
    [self updateMiddleMenuPosition];
    [self updateIndicatorView:animation];
}

- (void)configureMenus {
    //TODO 优化
    NSInteger menuCount = [self.delegate numberOfMenu:self];
    if (menuCount < 1)  return;
    
    [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGFloat menuLabelWidth = MAX((self.width - 2 * self.leading) / menuCount, self.minimumWidth);
    CGFloat totalWidth = 2 * self.leading;
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:menuCount];
    
    for (NSInteger i = 0; i < menuCount; i++) {
        WWPageMenuItem *label = [self viewForIndexInView:nil index:i];
        label.frame = CGRectMake(self.leading + i * menuLabelWidth, 0, menuLabelWidth, label.height-5);
        [self.scrollView addSubview:label];
        totalWidth += menuLabelWidth;
        CGRect rect = CGRectMake(label.x, 0, self.lineWidth>0?self.lineWidth:label.width + self.lineMargin * 2, label.height);
        [list addObject:[NSValue valueWithCGRect:rect]];
    }
    
    self.menuFrame = list;
    self.scrollView.contentSize = CGSizeMake(MAX(totalWidth, self.width), self.height);
    self.scrollView.frame = CGRectMake(0, 0, self.width, self.height);
    
    [self addIndicatorView];
}

// 更新中间menu位置：1、首先判断点击左右 对于scrollView宽度小于self的不需要滑动
- (void)updateMiddleMenuPosition {
    WWPageMenuItem *label = [self.scrollView viewWithTag:self.selectedIndex];
    CGFloat middleX = self.scrollView.contentOffset.x + self.scrollView.width * 0.5;
    CGFloat scrollDistance = self.scrollView.contentSize.width - self.width - self.scrollView.contentOffset.x;
    if (self.scrollView.contentSize.width <= self.width) {
        return;
    }
    
    //点击左侧，--> 滚动
    if (label.frame.origin.x <= middleX) {
        CGFloat offsetX = middleX - (label.x + label.width * 0.5);
        if (self.scrollView.contentOffset.x > offsetX ) {
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x - offsetX, 0) animated:YES];
        } else {
            [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        }
    } else {
        //右侧滚动 <--
        CGFloat offsetX =  (label.x + label.width * 0.5) - middleX;
        if ( scrollDistance > offsetX) {
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x + offsetX, 0) animated:YES];
        } else {
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x + scrollDistance, 0) animated:YES];
        }
    }
}

- (UIScrollView *)scrollView {
    if (_scrollView) return _scrollView;
    
    CGRect frame = CGRectMake(0, 0, self.width, self.height);
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:frame];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator   = NO;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.scrollsToTop = NO;
    scrollView.delegate = self;
    [self addSubview:scrollView];
    _scrollView = scrollView;
    return scrollView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = CGRectMake(0, 0, self.width, self.height - self.bottomViewHeight);
    self.bottomView.frame = CGRectMake(0, self.height - self.bottomViewHeight, self.width, self.bottomViewHeight);
    
    self.scrollView.contentOffset = CGPointMake(0, 0);
    [self layoutMenuLabels];
}

- (void)setBtmViewChangeHeight:(CGFloat)btmViewChangeHeight{
    self.bottomViewHeight = btmViewChangeHeight;
    [self layoutSubviews];
}

- (void)layoutMenuLabels {
    NSInteger menuCount = [self.scrollView.subviews count];
    for (NSInteger i = 0; i < menuCount; i++) {
        WWPageMenuItem *label = [self.scrollView viewWithTag:i + 1];
        if ([label isKindOfClass:[WWPageMenuItem class]]) {
            label.frame = CGRectMake(label.x, 0, label.width, self.scrollView.height);
        }
    }
    CGRect indicatorViewRect = self.indicatorView.frame;
    indicatorViewRect.origin.y = self.scrollView.height - self.lineHeight;
    self.indicatorView.frame = indicatorViewRect;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollView != scrollView)  return;
    
    if (scrollView.contentOffset.y == 0)  return;
    CGPoint contentOffset = scrollView.contentOffset;
    contentOffset.y = 0.0;
    scrollView.contentOffset = contentOffset;
}

#pragma mark -  WWScrollViewDelegate
- (WWPageMenuItem *)viewForIndexInView:(UIScrollView *)scrollView index:(NSInteger)index {
    WWPageMenuLabel *label = [[WWPageMenuLabel alloc] initWithFrame:CGRectMake(0, 0, 0, self.height)];
    label.text = [self pageMenu:self titleAtIndex:index];
    label.normalColor = self.normalColor;
    label.selectedColor = self.selectedColor;
    label.delegate = self;
    label.tag = index + 1;
    label.label.font = self.font;
    CGSize size = [label sizeThatFits:self.frame.size];
    CGRect frame = label.frame;
    frame.size = size;
    label.frame = frame;
    return label;
}

- (NSString *)pageMenu:(WWPageMenu *)menu titleAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(pageMenu:titleAtIndex:)]) {
        return [self.delegate pageMenu:self titleAtIndex:index];
    }
    return nil;
}

- (void)didClickedMenuLabel:(WWPageMenuItem *)label {
    if ([self.delegate respondsToSelector:@selector(pageMenu:didSelesctedIndex:)]) {
        [self.delegate pageMenu:self didSelesctedIndex:label.tag - 1];
    }
    [self setSelectedIndex:label.tag animation:YES];
}

- (void)slideMenuAtIndex:(NSInteger)index {
    [self slideMenuAtIndex:index animation:NO];
}

- (void)slideMenuAtIndex:(NSInteger)index animation:(BOOL)animation {
    if (index + 1 == self.selectedIndex)  return;
    
    [self setSelectedIndex:index + 1 animation:animation];
}

@end
