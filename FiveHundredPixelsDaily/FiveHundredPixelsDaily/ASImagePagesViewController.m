//
//  ASImagePagesViewController.m
//  FiveHundredPixelsDaily
//
//  Created by Alex Semenikhine on 2015-04-19.
//  Copyright (c) 2015 Alex Semenikhine. All rights reserved.
//

#import "ASImagePagesViewController.h"
#import "ASImageViewController.h"
#import "ASImageVCLinkedList.h"
#import "ASSettingsTableViewController.h"

@interface ASImagePagesViewController () <UIAlertViewDelegate>

@property UIPageViewController *pageViewController;
@property ASImageVCLinkedList *imagesLinkedList;
@property NSMutableArray *downloadedImages;

@end

@implementation ASImagePagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Bar buttons
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Thumbnails"] style:UIBarButtonItemStylePlain target:self action:@selector(goBackToThumbnails:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self  action:@selector(goToSettings:)];


    // Button gesture recognizers
    [self.nextButtonView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToNextImage:)]];
    [self.prevButtonView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToPrevImage:)]];
    [self.downloadButtonView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(downloadImage:)]];

    self.downloadedImages = [NSMutableArray new];

    // Create category controllers
    ASImageViewController *imageVC = (ASImageViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"FullImageVC"];
    imageVC.image = self.initialActiveImage;
    self.imagesLinkedList = [[ASImageVCLinkedList alloc] initWithImageVC:imageVC];

    // Create page view controller
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    [self.pageViewController setViewControllers:@[self.imagesLinkedList.imageVC] direction:UIPageViewControllerNavigationDirectionForward animated:false completion:nil];

    // Add it as child
    [self.pageViewController willMoveToParentViewController:self];
    [self addChildViewController:self.pageViewController];

    [self.containerView addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];

    // Add Contraints
    [self.pageViewController.view setTranslatesAutoresizingMaskIntoConstraints:false];
    [self.containerView addConstraints:@[
                                         [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.pageViewController.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
                                         [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.pageViewController.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0],
                                         [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.pageViewController.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
                                         [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.pageViewController.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                         ]];

    // For easier swiping
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;

    // Initial images
    [self.initialActiveImage requestFullImageIfNeeded];
    [self requestImagesForAdjacentVCs];
    
    // Button and title setup
    [self updateUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.initialActiveImage.category.fullQueue cancelAllOperations];
}

- (void)goToSettings:(id)sender {
    [self performSegueWithIdentifier:@"ShowSettings" sender:self];
}

- (void)goBackToThumbnails:(id)sender {
    [self.navigationController popViewControllerAnimated:true];
}

- (void)updateUI {
    self.navigationItem.title = self.imagesLinkedList.imageVC.image.name;

    // Update buttons
    if (self.imagesLinkedList.prev == nil) {
        self.prevButtonView.iconImageView.hidden = true;
        ((UIGestureRecognizer *)self.prevButtonView.gestureRecognizers.firstObject).enabled = false;
    } else {
        ((UIGestureRecognizer *)self.prevButtonView.gestureRecognizers.firstObject).enabled = true;
        self.prevButtonView.iconImageView.hidden = false;
    }

    if (self.imagesLinkedList.next == nil) {
        self.nextButtonView.iconImageView.hidden = true;
        ((UIGestureRecognizer *)self.nextButtonView.gestureRecognizers.firstObject).enabled = false;
    } else {
        ((UIGestureRecognizer *)self.nextButtonView.gestureRecognizers.firstObject).enabled = true;
        self.nextButtonView.iconImageView.hidden = false;
    }

    BOOL imageAlreadyDownloaded = [self.downloadedImages containsObject:self.imagesLinkedList.imageVC.image];
    ((UIGestureRecognizer *)self.downloadButtonView.gestureRecognizers.firstObject).enabled = !imageAlreadyDownloaded;
    self.downloadButtonView.alpha = imageAlreadyDownloaded ? 0.5 : 1.0;

    BOOL hideButtons = (self.imagesLinkedList.prev == nil && self.imagesLinkedList.next == nil);
    self.nextButtonView.hidden = hideButtons;
    self.prevButtonView.hidden = hideButtons;
}

- (void)downloadImage:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"ActiveAlbumIdentifier"] == nil) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Download album not selected" message:@"Please choose a Photos album to save photos to" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Go to Settings", nil];
        alertView.tintColor = [UIColor blackColor];
        [alertView show];
    } else {
        ASImage *image = self.imagesLinkedList.imageVC.image;
        [self.downloadedImages addObject:image];
        ((UIGestureRecognizer *)self.downloadButtonView.gestureRecognizers.firstObject).enabled = false;
        self.downloadButtonView.alpha = 0.5;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SaveImageToPhotos" object:nil userInfo:@{ @"image": image.full }];
    }
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) {
        [self performSegueWithIdentifier:@"ShowSettings" sender:self];
    }
}

#pragma mark - UIPageViewController DataSource

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed == YES) {
        ASImageViewController *newImageVC = (ASImageViewController *)self.pageViewController.viewControllers.firstObject;
        BOOL isNext = [self.imagesLinkedList.next.imageVC isEqual:newImageVC];
        // Cancel next/prev image fetch since we're going in the opposite direction
        if (isNext) {
            if (self.imagesLinkedList.prev != nil && self.imagesLinkedList.prev.imageVC.image.activeRequest != nil) [self.imagesLinkedList.prev.imageVC.image.activeRequest cancel];
        } else {
            if (self.imagesLinkedList.next != nil && self.imagesLinkedList.next.imageVC.image.activeRequest != nil) [self.imagesLinkedList.next.imageVC.image.activeRequest cancel];
        }

        // Set pointer to current linked list item, either we went to previous or next item in the linked list, we check which way here
        self.imagesLinkedList = isNext ? self.imagesLinkedList.next : self.imagesLinkedList.prev;
        [self requestImagesForAdjacentVCs];
        [self updateUI];
    }
}

- (void)requestImagesForAdjacentVCs {
    if (self.imagesLinkedList.prev != nil) [self.imagesLinkedList.prev.imageVC.image requestFullImageIfNeeded];
    if (self.imagesLinkedList.next != nil) [self.imagesLinkedList.next.imageVC.image requestFullImageIfNeeded];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(ASImageViewController *)viewController
{
    ASImageVCLinkedList *next = self.imagesLinkedList.next;

    return (next != nil) ? next.imageVC : nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(ASImageViewController *)viewController
{
    ASImageVCLinkedList *prev = self.imagesLinkedList.prev;

    return (prev != nil) ? prev.imageVC : nil;
}

- (void)goToPrevImage:(id)sender {
    ((UIGestureRecognizer *)self.prevButtonView.gestureRecognizers.firstObject).enabled = false;
    // Cancel next image fetch since we're going in the opposite direction
    if (self.imagesLinkedList.next != nil && self.imagesLinkedList.next.imageVC.image.activeRequest != nil) {
        [self.imagesLinkedList.next.imageVC.image.activeRequest cancel];
        NSLog(@"cancelling %@", self.imagesLinkedList.next.imageVC.image.name);
    }
    // Set new image
    self.imagesLinkedList = self.imagesLinkedList.prev;
    [self requestImagesForAdjacentVCs];

    [self.pageViewController setViewControllers:@[self.imagesLinkedList.imageVC]
                                      direction:UIPageViewControllerNavigationDirectionReverse
                                       animated:YES
                                     completion:nil];
    [self updateUI];
}

- (void)goToNextImage:(id)sender {
    ((UIGestureRecognizer *)self.nextButtonView.gestureRecognizers.firstObject).enabled = false;
    // Cancel prev image fetch since we're going in the opposite direction
    if (self.imagesLinkedList.prev != nil && self.imagesLinkedList.prev.imageVC.image.activeRequest != nil) {
        [self.imagesLinkedList.prev.imageVC.image.activeRequest cancel];
        NSLog(@"cancelling %@", self.imagesLinkedList.prev.imageVC.image.name);
    }
    // Set new image
    self.imagesLinkedList = self.imagesLinkedList.next;
    [self requestImagesForAdjacentVCs];

    [self.pageViewController setViewControllers:@[self.imagesLinkedList.imageVC]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
    [self updateUI];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowSettings"]) {
        UINavigationController *navVC = (UINavigationController *)segue.destinationViewController;
        ASSettingsTableViewController *settingsVC = (ASSettingsTableViewController *)navVC.topViewController;
        settingsVC.store = self.initialActiveImage.category.store;
    }
}

@end
