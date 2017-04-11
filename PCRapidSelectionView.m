//
//  PCRapidSelectionView.m
//  Ordervisto
//
//  Created by Maximilian Mackh on 25/09/15.
//  Copyright © 2015 Professional Consulting & Trading GmbH. All rights reserved.
//

#import "PCRapidSelectionView.h"

#import "UIImage+ImageEffects.h"

#import <objc/runtime.h>
#import <AudioToolbox/AudioServices.h>

NSInteger const kPCRapidSelectionViewTag = 1838;

@interface PCRapidSelectionView () <UIGestureRecognizerDelegate>

@property (nonatomic) IPDFUITheme theme;

@property (nonatomic) UIView *actionView;
@property (nonatomic,weak) UIView *parentView;
@property (nonatomic) UIImageView *blurredImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *buttonView;

@property (nonatomic,copy) void (^completionHandler)(NSInteger selectedIndex);

@property (nonatomic,getter=isInteractive) BOOL interactive;

@end

static BOOL isInteractive = NO;

static PCRapidSelectionView *_rapidSelectionView;


@implementation PCRapidSelectionView
{
    BOOL _animationInProgress;
}

void (*gOrigSendEvent)(id, SEL, UIEvent *);

+ (void)viewForParentView:(UIView *)parentView currentGuestureRecognizer:(UIGestureRecognizer *)guestureRecognizer interactive:(BOOL)interactive options:(NSArray *)options title:(NSString *)title completionHandler:(void(^)(NSInteger selectedIndex))completionHandler
{
    [self viewForParentView:parentView theme:IPDFUIThemeLight currentGuestureRecognizer:guestureRecognizer interactive:interactive options:options title:title completionHandler:completionHandler];
}

+ (void)viewForParentView:(UIView *)parentView theme:(IPDFUITheme)theme currentGuestureRecognizer:(UIGestureRecognizer *)guestureRecognizer interactive:(BOOL)interactive options:(NSArray *)options title:(NSString *)title completionHandler:(void(^)(NSInteger selectedIndex))completionHandler;
{
    if ([parentView viewWithTag:kPCRapidSelectionViewTag]) return;
    
/*
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    if (interactive) AudioServicesPlaySystemSoundWithVibration(4095,nil,@{@"Intensity":@(1),@"VibePattern":@[@(YES),@(40)]});
#pragma clang diagnostic pop
*/
    UIWindow *currentWindow = [[UIApplication sharedApplication] keyWindow];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        Method origMethod = class_getInstanceMethod([currentWindow class], @selector(sendEvent:));
        gOrigSendEvent = (void *)method_getImplementation(origMethod);
        if(!class_addMethod(currentWindow.class, @selector(sendEvent:), (IMP)OverrideSendEvent, method_getTypeEncoding(origMethod)))
            method_setImplementation(origMethod, (IMP)OverrideSendEvent);
    });

    PCRapidSelectionView *selectionView = [[PCRapidSelectionView alloc] initWithFrame:parentView.bounds];
    selectionView.interactive = interactive;
    selectionView.theme = theme;
    [selectionView setParentView:parentView guesture:guestureRecognizer options:options title:title];
    selectionView.completionHandler = completionHandler;

    __weak PCRapidSelectionView *wSV = selectionView;
    [selectionView show:YES completionHandler:^
    {
        [wSV becomeFirstResponder];
    }];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)setParentView:(UIView *)parentView guesture:(UIGestureRecognizer *)guesture options:(NSArray *)options title:(NSString *)title
{
    self.tag = kPCRapidSelectionViewTag;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.translatesAutoresizingMaskIntoConstraints = YES;
    
    [parentView addSubview:self];
    _parentView = parentView;
    
    CGFloat buttonHeight = 58;
    CGFloat titleLabelHeight = 58;
    CGFloat titleDistance = 8;
    CGFloat cornerRadius = 10;
    
    CGFloat width = MIN(parentView.bounds.size.width, 400);
    CGFloat widthInsetPadding = 10;
    
    CGFloat realWidth = width - widthInsetPadding * 2;
    
    CGFloat titleHeightCalculated = [self heightForString:title maxWidth:realWidth];
    titleLabelHeight = (titleHeightCalculated <= 58) ? 58 : titleHeightCalculated + 18;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(widthInsetPadding, 0, realWidth, buttonHeight * options.count + titleLabelHeight + titleDistance)];
    
    
    self.actionView = containerView;
    containerView.center = self.center;
    containerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    containerView.translatesAutoresizingMaskIntoConstraints = YES;
    containerView.frame = CGRectOffset(containerView.frame, 0, parentView.bounds.size.height / 2 + containerView.bounds.size.height / 2);
    
    BOOL lightTheme = (self.theme == IPDFUIThemeLight);
    
    UIImage *blurredImage = (lightTheme) ? [UIImage blurredImageForView:parentView] : [UIImage darkishBlurredImageForView:parentView];
    
    UIImageView *blurredImageView = [[UIImageView alloc] initWithImage:blurredImage];
    blurredImageView.alpha = 0.0;
    blurredImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    blurredImageView.translatesAutoresizingMaskIntoConstraints = YES;
    self.blurredImageView = blurredImageView;
    [self addSubview:blurredImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, titleLabelHeight + 10, containerView.bounds.size.width, titleLabelHeight)];
    titleLabel.textColor = (lightTheme) ? [UIColor colorWithWhite:0.0 alpha:0.7] : [UIColor colorWithWhite:1.0 alpha:0.7];
    titleLabel.text = title;
    titleLabel.numberOfLines = 0;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:17.5];
    titleLabel.layer.cornerRadius = cornerRadius;
    [containerView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, titleLabelHeight + titleDistance, containerView.bounds.size.width, options.count * buttonHeight)];
    buttonView.layer.cornerRadius = cornerRadius;
    if (!lightTheme)
    {
        buttonView.layer.borderColor = [UIColor colorWithWhite:0.4 alpha:1.0].CGColor;
        buttonView.layer.borderWidth = 1;
    }
    buttonView.clipsToBounds = YES;
    self.buttonView = buttonView;
    [containerView addSubview:buttonView];
    
    NSInteger increment = 0;
    for (NSString *option in options)
    {
        BOOL addLine = (increment != 0);
        
        PCRapidButton *button = [[PCRapidButton alloc] initWithFrame:CGRectMake(0, increment * buttonHeight, containerView.bounds.size.width - ((addLine) ? - 1 : 0), buttonHeight)];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = increment;
        button.titleLabel.font = [UIFont systemFontOfSize:18.5];
        button.backgroundColor = [UIColor clearColor];
        
        [button setTitleColor:(lightTheme) ? [UIColor colorWithRed:0 green:0.46 blue:1 alpha:1] : [UIColor whiteColor] forState:UIControlStateNormal];
        
        if (addLine)
        {
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, increment * buttonHeight, containerView.bounds.size.width, 0.5)];
            separator.backgroundColor = [UIColor colorWithWhite:(lightTheme)?0.8:0.4 alpha:1.0];
            [buttonView addSubview:separator];
        }
        
        [button setTitle:option forState:UIControlStateNormal];
        [buttonView addSubview:button];
        
        increment++;
    }
    
    [self addSubview:containerView];

    
    guesture.enabled = NO;
    guesture.enabled = YES;
    
}

- (CGFloat)heightForString:(NSString *)string maxWidth:(CGFloat)width
{
    CGFloat height = (!string.length) ? 0 : [string boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17.5]} context:nil].size.height;
    
    return height;
}

- (void)show:(BOOL)show completionHandler:(void(^)())completionHandler;
{
    isInteractive = self.interactive;
    _animationInProgress = YES;
    
    BOOL lightTheme = (self.theme == IPDFUIThemeLight);
    
    [UIView animateWithDuration:0.2 animations:^
    {
        self.blurredImageView.alpha = show;
        
        self.titleLabel.layer.backgroundColor = [UIColor colorWithWhite:(lightTheme)?1.0:0.3 alpha:(show)?0.6:1.0].CGColor;
        self.buttonView.layer.backgroundColor = [UIColor colorWithWhite:(lightTheme)?1.0:0.0 alpha:(show)?0.96:1.0].CGColor;
    }];
    
    NSInteger buttonViewCountSubviewCount = self.buttonView.subviews.count;
    
    [UIView animateWithDuration:!buttonViewCountSubviewCount?0.0:0.5 delay:(show)? 0.2 : 0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:UIViewAnimationOptionAllowUserInteraction animations:^
    {
        self.titleLabel.frame = CGRectOffset(self.titleLabel.frame, 0, (10 + self.titleLabel.bounds.size.height) * ((show) ? -1 : 1));
    } completion:nil];
    
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut animations:^{
        
        CGFloat distance = self.bounds.size.height/2 + self.actionView.bounds.size.height /2 ;
        self.actionView.frame = CGRectOffset(self.actionView.frame, 0, distance  * ((show) ? -1 :  1) );
    }
    completion:^(BOOL finished)
    {
        _animationInProgress = NO;
        if (!show) [self removeFromSuperview];
        if (completionHandler) completionHandler();
        if (!completionHandler && self.completionHandler) self.completionHandler(NSNotFound);
    }];
    
}

- (void)buttonPressed:(UIButton *)button
{
    __weak typeof(self) weakSelf = self;
    [self show:NO completionHandler:^
    {
        if (weakSelf.completionHandler) weakSelf.completionHandler(button.tag);
    }];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (touches.anyObject.view == self)
    {
        [self show:NO completionHandler:nil];
    }
    
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    
    if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseMoved)
    {
        BOOL hasHit = NO;
        
        CGPoint touchLocation = [touch locationInView:self];
        
        for (id subview in self.buttonView.subviews)
        {
            if (_animationInProgress) break;
            
            if (![subview isKindOfClass:[PCRapidButton class]]) continue;
            
            PCRapidButton *button = subview;
            CGRect buttonInView = [button convertRect:button.bounds toView:self];
            
            BOOL hitButton = CGRectContainsPoint(buttonInView, touchLocation);
            
            if (!hasHit) hasHit = hitButton;
            
            [UIView animateWithDuration:0.05 animations:^
            {
                [button setHighlighted:hitButton];
            }];
            
            if (hitButton && touch.phase == UITouchPhaseEnded)
            {
                [button sendActionsForControlEvents:UIControlEventTouchUpInside];
                return;
            }
            
            if (touch.phase == UITouchPhaseMoved) continue;
        }
        
        if (!hasHit && touch.phase == UITouchPhaseEnded) [self show:NO completionHandler:nil];
        return;
    }
    
    [super touchesMoved:touches withEvent:event];
}

static void OverrideSendEvent(UIWindow *self, SEL _cmd, UIEvent *event)
{
    gOrigSendEvent(self, _cmd, event);
    
    if ([PCRapidSelectionView isInteractive])
    {
        
        UITouch *touch = event.allTouches.anyObject;
        
        if (!_rapidSelectionView)
        {
            _rapidSelectionView = (id)[[[UIApplication sharedApplication] keyWindow] viewWithTag:kPCRapidSelectionViewTag];
        }
        
        if (touch && _rapidSelectionView)
        {
            [_rapidSelectionView touchesMoved:event.allTouches withEvent:event];
            
            if (touch.phase == UITouchPhaseEnded)
            {
                _rapidSelectionView = nil;
            }
            
            return;
        }
    }
}

+ (BOOL)isInteractive
{
    return isInteractive;
}

@end

@interface PCRapidButton ()

@property (nonatomic) UIColor *backupBackgroundColor;

@end

@implementation PCRapidButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    self.backgroundColor = (highlighted) ? [UIColor colorWithWhite:0.8 alpha:0.6] : [UIColor clearColor];
}

@end
