//
//  FlipsideViewController.h
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TapDetectingImageView.h"

@class FlipsideViewController;
@class MainViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UIViewController

@property (weak, nonatomic) IBOutlet id <FlipsideViewControllerDelegate> delegate;
@property (strong) MainViewController *mainViewController;

- (IBAction)done:(id)sender;

@end

#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5
#define AUTOSCROLL_THRESHOLD 30

@interface InchMMViewController : FlipsideViewController <UIScrollViewDelegate, TapDetectingImageViewDelegate>
{
    NSTimer *autoscrollTimer;  // Timer used for auto-scrolling.
    float autoscrollDistance;  // Distance to scroll the thumb view when auto-scroll timer fires.
}
@property (weak, nonatomic) IBOutlet TapDetectingImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
- (IBAction)finish:(id)sender;

@end
