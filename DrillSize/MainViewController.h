//
//  MainViewController.h
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 PolyMicro Systems. All rights reserved.
//

#import "ImageViewController.h"

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

// useful constants for your font size-related code
#define kPickerViewDefaultTitleFontSize 20.0f
#define kDatePickerTitleFontSize 25.0f
#define kDatePickerLabelFontSize 21.0f

@interface UIPickerView (SelectionBarLabelSupport)

// The primary API to add a label to the given component.
// If you want to match the look of UIDatePicker, use 21pt as pointSize and 25pt as the font size of your content views (titlePointSize).
// (Note that UIPickerView defaults to 20pt items, so you need to use custom views. See a helper method below.)
// Repeated calls will change the label with an animation effect similar to UIDatePicker's one.
//
// To call this method on viewDidLoad, please call [pickerView layoutSubviews] first so that all subviews
// drillSizesComponent created.
- (void)addLabel:(NSString *)label ofSize:(CGFloat)pointSize toComponent:(NSInteger)component leftAlignedAt:(CGFloat)offset baselineAlignedWithFontOfSize:(CGFloat)titlePointSize;

// A helper method for your delegate's "pickerView:viewForRow:forComponent:reusingView:".
// Creates a propertly positioned right-aligned label of the given size, and also handles reuse.
// The actual UILabel is a child of the returned view, use [returnedView viewWithTag:1] to retrieve the label.
- (UIView *)viewForShadedLabelWithText:(NSString *)label ofSize:(CGFloat)pointSize forComponent:(NSInteger)component rightAlignedAt:(CGFloat)offset reusingView:(UIView *)view;

// Creates a shaded label of the given size, looking similar to the labels used by UIPickerView/UIDatePicker.

- (UILabel *)shadedLabelWithText:(NSString *)label ofSize:(CGFloat)pointSize;

@end

#import "CoolButton.h"
#import "GradientButton.h"

#define kSizes 0
#define kValues 1
#define kMetrics 2

@interface MainViewController : UIViewController <ImageViewControllerDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIVideoEditorControllerDelegate, ADBannerViewDelegate> {
    NSArray *drillsComponent;
    NSArray *valuesComponent;
    NSArray *metricsComponent;
}
@property(nonatomic) BOOL bannerIsVisible;
@property(weak, nonatomic) IBOutlet UIPickerView *sizePicker;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic) UIPopoverController *imagePopoverController;
@property(weak, nonatomic) IBOutlet ADBannerView *adBannerView;
@property(weak, nonatomic) IBOutlet GradientButton *mmInchButton;
@property(weak, nonatomic) IBOutlet GradientButton *mmSizeButton;

@property(copy) NSArray *drillsComponent;
@property(copy) NSArray *valuesComponent;
@property(copy) NSArray *metricsComponent;

- (IBAction)togglePopover:(id)sender;
@end


