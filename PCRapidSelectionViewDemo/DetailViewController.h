//
//  DetailViewController.h
//  PCRapidSelectionViewDemo
//
//  Created by Maximilian Mackh on 27/09/15.
//  Copyright © 2015 Maximilian Mackh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

