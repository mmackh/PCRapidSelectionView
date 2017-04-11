//
//  PCRapidSelectionView.h
//  Ordervisto
//
//  Created by Maximilian Mackh on 25/09/15.
//  Copyright © 2015 Professional Consulting & Trading GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kPCRapidSelectionViewTag;

typedef enum : NSUInteger
{
    IPDFUIThemeLight,
    IPDFUIThemeDark,
} IPDFUITheme;


@interface PCRapidSelectionView : UIView

+ (void)viewForParentView:(UIView *)parentView currentGuestureRecognizer:(UIGestureRecognizer *)guestureRecognizer interactive:(BOOL)interactive options:(NSArray *)options title:(NSString *)title completionHandler:(void(^)(NSInteger selectedIndex))completionHandler;

+ (void)viewForParentView:(UIView *)parentView theme:(IPDFUITheme)theme currentGuestureRecognizer:(UIGestureRecognizer *)guestureRecognizer interactive:(BOOL)interactive options:(NSArray *)options title:(NSString *)title completionHandler:(void(^)(NSInteger selectedIndex))completionHandler;

@end

@interface PCRapidButton : UIButton

@end
