//
//  MainViewController.h
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"

#import <UIKit/UIKit.h>

#define kDecimals 0
#define kFractions 1
#define kMetric 2

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIVideoEditorControllerDelegate> {
    NSArray *decimalComponent, *fractionsComponent, *metricComponent;
}
@property(weak, nonatomic) IBOutlet UIPickerView *sizePicker;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property(nonatomic, retain) NSArray *decimalComponent, *fractionsComponent, *metricComponent;

@end
