//
//  MainViewController.m
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MainViewController.h"

// used to find existing component labels among UIPicker's children
#define kMagicTag 89464534
// a private UIKit implementation detail, but we do degrade gracefully in case it stops working
#define kSelectionBarClassName @"_UIPickerViewSelectionBar"

// used to sort per-component selection bars in a left-to-right order
static NSInteger compareViews(UIView *a, UIView *b, void *context) {
    CGFloat ax = a.frame.origin.x, bx = b.frame.origin.x;
    if (ax < bx)
        return -1;
    else if (ax > bx)
        return 1;
    else
        return 0;
}


@implementation UIPickerView (SelectionBarLabelSupport)

- (UILabel *)shadedLabelWithText:(NSString *)label ofSize:(CGFloat)pointSize {
    UIFont *font = [UIFont boldSystemFontOfSize:pointSize];
    CGSize size = [label sizeWithFont:font];
    UILabel *labelView = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)] autorelease];
    labelView.font = font;
    labelView.adjustsFontSizeToFitWidth = NO;
    labelView.shadowOffset = CGSizeMake(1, 1);
    labelView.textColor = [UIColor blackColor];
    labelView.shadowColor = [UIColor whiteColor];
    labelView.opaque = NO;
    labelView.backgroundColor = [UIColor clearColor];
    labelView.text = label;
    labelView.userInteractionEnabled = NO;
    return labelView;
}

- (UIView *)viewForShadedLabelWithText:(NSString *)title ofSize:(CGFloat)pointSize forComponent:(NSInteger)component rightAlignedAt:(CGFloat)offset reusingView:(UIView *)view {
    UILabel *label;
    UIView *wrapper;
    if (view != nil) {
        wrapper = view;
        label = (UILabel *) [wrapper viewWithTag:1];
    } else {
        CGFloat width = [self.delegate pickerView:self widthForComponent:component];

        label = [self shadedLabelWithText:title ofSize:pointSize];
        CGSize size = label.frame.size;
        label.frame = CGRectMake(0, 0, offset, size.height);
        label.tag = 1;
        label.textAlignment = UITextAlignmentRight;
        label.autoresizingMask = UIViewAutoresizingFlexibleHeight;

        wrapper = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, width, size.height)] autorelease];
        wrapper.autoresizesSubviews = NO;
        wrapper.userInteractionEnabled = NO;
        [wrapper addSubview:label];
    }
    label.text = title;
    return wrapper;
}

- (void)addLabel:(NSString *)label ofSize:(CGFloat)pointSize toComponent:(NSInteger)component leftAlignedAt:(CGFloat)offset baselineAlignedWithFontOfSize:(CGFloat)titlePointSize {
    NSParameterAssert(component < [self numberOfComponents]);

    NSInteger tag = kMagicTag + component;
    UILabel *oldLabel = (UILabel *) [self viewWithTag:tag];
    if (oldLabel != nil && [oldLabel.text isEqualToString:label])
        return;

    NSInteger n = [self numberOfComponents];
    CGFloat total = 0.0;
    for (int c = 0; c < component; c++)
        offset += [self.delegate pickerView:self widthForComponent:c];
    for (int c = 0; c < n; c++)
        total += [self.delegate pickerView:self widthForComponent:c];
    offset += (self.bounds.size.width - total) / 2;

    offset += 2 * component; // internal UIPicker metrics, measured on a screenshot
    offset += 4; // add a gap

    CGFloat baselineHeight = [@"X" sizeWithFont:[UIFont boldSystemFontOfSize:titlePointSize]].height;
    CGFloat labelHeight = [@"X" sizeWithFont:[UIFont boldSystemFontOfSize:pointSize]].height;

    UILabel *labelView = [self shadedLabelWithText:label ofSize:pointSize];
    labelView.frame = CGRectMake(offset,
            (self.bounds.size.height - baselineHeight) / 2 + (baselineHeight - labelHeight) - 1,
            labelView.frame.size.width,
            labelView.frame.size.height);
    labelView.tag = tag;

    UIView *selectionBarView = nil;
    NSMutableArray *selectionBars = [NSMutableArray array];
    for (UIView *subview in self.subviews) {
        if ([[[subview class] description] isEqualToString:kSelectionBarClassName])
            [selectionBars addObject:subview];
    }
    if ([selectionBars count] == n) {
        [selectionBars sortUsingFunction:compareViews context:NULL];
        selectionBarView = [selectionBars objectAtIndex:component];
    }
    if (oldLabel != nil) {
        [UIView beginAnimations:nil context:oldLabel];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(YS_barLabelHideAnimationDidStop:finished:context:)];
        oldLabel.alpha = 0.0f;
        [UIView commitAnimations];
    }
    // if the selection bar hack stops working, degrade to using 60% alpha
    CGFloat normalAlpha = (selectionBarView == nil ? 0.6f : 1.0f);
    if (selectionBarView != nil)
        [self insertSubview:labelView aboveSubview:selectionBarView];
    else
        [self addSubview:labelView];
    if (oldLabel != nil) {
        labelView.alpha = 0.0f;
        [UIView beginAnimations:nil context:oldLabel];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        labelView.alpha = normalAlpha;
        [UIView commitAnimations];
    } else {
        labelView.alpha = normalAlpha;
    }
}

- (void)YS_barLabelHideAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(UIView *)oldLabel {
    [oldLabel removeFromSuperview];
}

@end

@interface MainViewController ()
- (IBAction)togglePopover:(id)sender;

@end

@implementation MainViewController

@synthesize sizePicker = _sizePicker;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize decimalComponent, fractionsComponent, metricComponent;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *array = [[NSArray alloc] initWithObjects:@"1/64", @"1/32", @"3/64", @"1/16", @"5/64", @"3/32", @"7/64", @"1/8", @"9/64", @"5/32", @"11/64", @"3/16", @"13/64", @"7/32", @"15/64", @"1/4", @"17/64", @"9/32", @"19/64", @"5/16", @"21/64", @"11/32", @"23/64", @"3/8", @"25/64", @"13/32", @"27/64", @"7/16", @"29/64", @"15/32", @"31/64", @"1/2", @"33/64", @"17/32", @"35/64", @"9/16", @"37/64", @"19/32", @"39/64", @"5/8", @"41/64", @"21/32", @"43/64", @"11/16", @"45/64", @"23/32", @"47/64", @"3/4", @"49/64", @"25/32", @"51/64", @"13/16", @"53/64", @"27/32", @"55/64", @"7/8", @"57/64", @"29/32", @"59/64", @"15/16", @"61/64", @"31/32", @"63/64", @"1", nil];
    NSMutableArray *decimals = [NSMutableArray arrayWithCapacity:64];
    NSMutableArray *fractions = [NSMutableArray arrayWithCapacity:64];
    NSMutableArray *metrics = [NSMutableArray arrayWithCapacity:64];
    NSNumber *value;
    NSNumber *metric;
    float mm = (float) 25.4 / (float) 64;
    int z = 0;
    for (float i = 64; i > 0; i--) {
        value = [NSNumber numberWithFloat:(float) 1 / i];
        [decimals addObject:value];
        [fractions addObject:[array objectAtIndex:(NSUInteger) z++]];
        metric = [NSNumber numberWithFloat:z * mm];
        [metrics addObject:metric];
    }

    self.decimalComponent = decimals;
    self.fractionsComponent = fractions;
    self.metricComponent = metrics;
}

- (void)viewDidUnload {
    [self setSizePicker:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (component) {
        case kDecimals:
            return [decimalComponent count];
        case kFractions:
            return [fractionsComponent count];
        case kMetric:
            return [metricComponent count];
        default:
            return 0;
    }
}

#pragma mark Picker Delegate Methods
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (component) {
        case kDecimals:
        {
            [pickerView selectRow:row inComponent:kFractions animated:YES];
            [pickerView selectRow:row inComponent:kMetric animated:YES];
            break;
        }
        case kFractions:
            [pickerView selectRow:row inComponent:kDecimals animated:YES];
            [pickerView selectRow:row inComponent:kMetric animated:YES];
            break;
        case kMetric:
        {
            [pickerView selectRow:row inComponent:kFractions animated:YES];
            [pickerView selectRow:row inComponent:kDecimals animated:YES];
            break;
        }
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSString *formattedNumberString = @"NaN";
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:4];
    [numberFormatter setMaximumFractionDigits:4];
    [numberFormatter setPaddingCharacter:@"0"];
    [numberFormatter setPaddingPosition:NSNumberFormatterPadAfterSuffix];
    switch (component) {
        case kDecimals:
        {
            NSNumber *decimal = [decimalComponent objectAtIndex:(NSUInteger) row];
            formattedNumberString = [NSString stringWithString:[numberFormatter stringFromNumber:decimal]];
            break;
        }
        case kFractions:
        {
            formattedNumberString = [fractionsComponent objectAtIndex:(NSUInteger) row];
        }
            break;
        case kMetric:
        {
            NSNumber *metric = [metricComponent objectAtIndex:(NSUInteger) row];
            formattedNumberString = [NSString stringWithString:[numberFormatter stringFromNumber:metric]];
        }
            break;
    }
    NSLog(@"titleForRow: %@", formattedNumberString);
    return formattedNumberString;
}


//- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
//{
//    if (component == kFractions) {
//
//    }
//}
#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *) segue popoverController];
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        }
    }
}

- (IBAction)togglePopover:(id)sender {
    if (self.flipsidePopoverController) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}

@end
