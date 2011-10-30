//
//  FlipsideViewController.h
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@interface InchMMViewController : FlipsideViewController

- (IBAction)finish:(id)sender;

@end
