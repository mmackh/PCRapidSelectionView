//
//  PCRapidSelectionView.h
//  Ordervisto
//
//  Created by Maximilian Mackh on 25/09/15.
//  Copyright © 2015 Professional Consulting & Trading GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kPCRapidSelectionViewTag;

@interface PCRapidSelectionView : UIView

+ (void)viewForParentView:(UIView *)parentView currentGuestureRecognizer:(UIGestureRecognizer *)guestureRecognizer interactive:(BOOL)interactive options:(NSArray *)options title:(NSString *)title completionHandler:(void(^)(NSInteger selectedIndex))completionHandler;

@end
