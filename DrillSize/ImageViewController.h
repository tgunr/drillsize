//
//  ImageViewController.h
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TapDetectingImageView.h"

@class ImageViewController;
@class MainViewController;

@protocol ImageViewControllerDelegate
- (void)imageViewControllerDidFinish:(ImageViewController *)controller;
@end

@interface ImageViewController : UIViewController

@property (weak, nonatomic) IBOutlet id <ImageViewControllerDelegate> delegate;
@property (strong) MainViewController *mainViewController;

- (IBAction)done:(id)sender;

@end

#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5
#define AUTOSCROLL_THRESHOLD 30

@interface InchMMViewController : ImageViewController <UIScrollViewDelegate, TapDetectingImageViewDelegate>
{
    NSTimer *autoscrollTimer;  // Timer used for auto-scrolling.
    float autoscrollDistance;  // Distance to scroll the thumb view when auto-scroll timer fires.
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
- (IBAction)finish:(id)sender;

@end

@interface SizeMMViewController : ImageViewController <UIScrollViewDelegate, TapDetectingImageViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *diamLabelView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
- (IBAction)finish:(id)sender;

@end
