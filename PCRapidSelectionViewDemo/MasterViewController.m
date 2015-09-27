//
//  MasterViewController.m
//  PCRapidSelectionViewDemo
//
//  Created by Maximilian Mackh on 27/09/15.
//  Copyright © 2015 Maximilian Mackh. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

#import "PCRapidSelectionView.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"PCRSV Demo";
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    UIButton *addButton = [[UIButton alloc] init];
    addButton.titleLabel.font = [UIFont systemFontOfSize:17.5];
    [addButton setTitle:@"Add Row" forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(insertNewObject:) forControlEvents:UIControlEventTouchUpInside];
    [addButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(secretMenu:)];
    longPress.minimumPressDuration = 0.3;
    [addButton addGestureRecognizer:longPress];
    [addButton sizeToFit];
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)secretMenu:(UIGestureRecognizer *)gesture
{
    [PCRapidSelectionView viewForParentView:self.navigationController.view currentGuestureRecognizer:gesture interactive:YES options:@[@"Enable Debug",@"Inspect View",@"Change Gestures",@"More..."] title:@"Advanced Options" completionHandler:^(NSInteger selectedIndex)
    {
        NSLog(@"Secret menu selected: %i",(int)selectedIndex);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = sender;
        NSDate *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDate *object = self.objects[indexPath.row];
    cell.textLabel.text = [object description];
    
    if (cell.contentView.gestureRecognizers.count == 1)
    {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:24];
        cell.contentView.backgroundColor = [UIColor colorWithHue:0.07*self.objects.count saturation:1.0 brightness:1.0 alpha:0.9];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(openContextMenu:)];
        longPress.minimumPressDuration = 0.3;
        longPress.cancelsTouchesInView = YES;
        [cell.contentView addGestureRecognizer:longPress];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushDetail:)];
        tap.cancelsTouchesInView = YES;
        [cell.contentView addGestureRecognizer:tap];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)pushDetail:(UITapGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [self indexPathForGesture:gesture];
    [self performSegueWithIdentifier:@"showDetail" sender:indexPath];
}

- (void)openContextMenu:(UILongPressGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [self indexPathForGesture:gesture];
    
    __weak typeof(self) weakSelf = self;
    [PCRapidSelectionView viewForParentView:self.navigationController.view currentGuestureRecognizer:gesture interactive:YES options:@[@"Show Detail",[NSString stringWithFormat:@"Delete Row %i",(int)indexPath.row + 1]] title:@"Quick Select" completionHandler:^(NSInteger selectedIndex)
    {
        if (selectedIndex == NSNotFound)
        {
            NSLog(@"Cancelled");
        }
        if (selectedIndex == 0)
        {
            [weakSelf performSegueWithIdentifier:@"showDetail" sender:indexPath];
        }
        if (selectedIndex == 1)
        {
            [weakSelf tableView:weakSelf.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        }
    }];
}

- (NSIndexPath *)indexPathForGesture:(UIGestureRecognizer *)gesture
{
    return [self.tableView indexPathForCell:(id)gesture.view.superview];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end
