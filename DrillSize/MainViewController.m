//
//  MainViewController.m
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

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
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UILabel *labelView = [[UILabel alloc] initWithFrame:rect];
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
        CGRect rect = CGRectMake(0, 0, width, size.height);
        label.frame = CGRectMake(0, 0, offset, size.height);
        label.tag = 1;
        label.textAlignment = UITextAlignmentRight;
        label.autoresizingMask = UIViewAutoresizingFlexibleHeight;

        wrapper = [[UIView alloc] initWithFrame:rect];
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
	CGRect labelRect =CGRectMake(offset,
            (self.bounds.size.height - baselineHeight) / 2 + (baselineHeight - labelHeight) - 1,
            labelView.frame.size.width,
            labelView.frame.size.height);
	labelView.frame = labelRect;
    labelView.tag = tag;

    UIView *selectionBarView = nil;
    NSMutableArray *selectionBars = [NSMutableArray array];
    for (UIView *subview in self.subviews) {
        if ([[[subview class] description] isEqualToString:kSelectionBarClassName])
            [selectionBars addObject:subview];
    }
    if ([selectionBars count] == n) {
        [selectionBars sortUsingFunction:compareViews context:NULL];
        selectionBarView = [selectionBars objectAtIndex:(NSUInteger) component];
    }
    if (oldLabel != nil) {
        [UIView beginAnimations:nil context:(__bridge void *) oldLabel];
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
        [UIView beginAnimations:nil context:(__bridge void *) oldLabel];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        labelView.alpha = normalAlpha;
        [UIView commitAnimations];
    } else {
        labelView.alpha = normalAlpha;
    }
}

- (void)addOffsetLabel:(NSString *)label ofSize:(CGFloat)pointSize toComponent:(NSInteger)component leftAlignedAt:(CGFloat)hoffset bottomAlignedAt:(CGFloat)voffset {
    NSParameterAssert(component < [self numberOfComponents]);
	
    NSInteger tag = kMagicTag + component;
    UILabel *oldLabel = (UILabel *) [self viewWithTag:tag];
    if (oldLabel != nil && [oldLabel.text isEqualToString:label])
        return;
	
    NSInteger n = [self numberOfComponents];
    CGFloat total = 0.0;
	CGSize rowSize;
	CGFloat labelhoffset = hoffset;
    for (int c = 0; c < component; c++)
        labelhoffset += [self.delegate pickerView:self widthForComponent:c];
    for (int c = 0; c < n; c++) {
        total += [self.delegate pickerView:self widthForComponent:c];
		rowSize = [self rowSizeForComponent:c];
	}	
	CGRect myBounds = self.bounds;
	CGSize mySize = myBounds.size;
	CGFloat myWidth = mySize.width;
    labelhoffset += (myWidth - total) / 2;
	
    labelhoffset += 2 * component; // internal UIPicker metrics, measured on a screenshot
    labelhoffset += 4; // add a gap
	
//    CGFloat baselineHeight = [@"X" sizeWithFont:[UIFont boldSystemFontOfSize:voffset]].height;
//    CGFloat labelHeight = [@"X" sizeWithFont:[UIFont boldSystemFontOfSize:pointSize]].height;
	
    UILabel *labelView = [self shadedLabelWithText:label ofSize:pointSize];
	CGRect labelRect =CGRectMake((labelhoffset + hoffset),
								 (mySize.height / 2) + voffset,
								 labelView.frame.size.width,
								 labelView.frame.size.height);
	labelView.frame = labelRect;
    labelView.tag = tag;
	
    UIView *selectionBarView = nil;
    NSMutableArray *selectionBars = [NSMutableArray array];
    for (UIView *subview in self.subviews) {
        if ([[[subview class] description] isEqualToString:kSelectionBarClassName])
            [selectionBars addObject:subview];
    }
    if ([selectionBars count] == n) {
        [selectionBars sortUsingFunction:compareViews context:NULL];
        selectionBarView = [selectionBars objectAtIndex:(NSUInteger) component];
    }
    if (oldLabel != nil) {
        [UIView beginAnimations:nil context:(__bridge void *) oldLabel];
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
        [UIView beginAnimations:nil context:(__bridge void *) oldLabel];
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

@implementation MainViewController

@synthesize sizePicker = _sizePicker;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize imagePopoverController = _imagePopoverController;
@synthesize adBannerView;
@synthesize mmInchButton;
@synthesize mmSizeButton;
@synthesize sixtyFoursOnly;
@synthesize drillsComponent;
@synthesize valuesComponent;
@synthesize metricsComponent;
@synthesize sixtyFoursDrillsComponent;
@synthesize sixtyFoursValuesComponent;
@synthesize sixtyFoursMetricsComponent;
@synthesize bannerIsVisible;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)updateDecimalLabel {
//    NSInteger floor = [self.sizePicker numberOfRowsInComponent:0] - [self.sizePicker selectedRowInComponent:0];
//    NSString *suffix = @"th";
//    if (((floor % 100) / 10) != 1) {
//        switch (floor % 10) {
//            case 1:  suffix = @"st"; break;
//            case 2:  suffix = @"nd"; break;
//            case 3:  suffix = @"rd"; break;
//        }
//    }
//    [self.sizePicker addLabel:[NSString stringWithFormat:@"%@ in", suffix]
    [self.sizePicker addOffsetLabel:@"size"
                       ofSize:12
                  toComponent:0
                leftAlignedAt:20
			  bottomAlignedAt:7];
}

- (void)updateFractionLabel {
    [self.sizePicker addOffsetLabel:@"in"
                       ofSize:12
                  toComponent:1
                leftAlignedAt:20
			  bottomAlignedAt:7];
}

- (void)updateMetricLabel {
    [self.sizePicker addOffsetLabel:@"mm"
                       ofSize:12
                  toComponent:2
                leftAlignedAt:20
			  bottomAlignedAt:7];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *drillArray = [[NSArray alloc] initWithObjects:@"80", @"79", @"1/64", @"78", @"77", @"76", @"75", @"74", @"73", @"72", @"71", @"70", @"69", @"68", @"1/32", @"67", @"66", @"65", @"64", @"63", @"62", @"61", @"60", @"59", @"58", @"57", @"56", @"3/64", @"55", @"54", @"53", @"1/16", @"52", @"51", @"50", @"49", @"48", @"5/64", @"47", @"46", @"45", @"44", @"43", @"42", @"3/32", @"41", @"40", @"39", @"38", @"37", @"36", @"7/64", @"35", @"34", @"33", @"32", @"31", @"1/8", @"30", @"29", @"28", @"9/64", @"27", @"26", @"25", @"24", @"23", @"5/32", @"22", @"21", @"20", @"19", @"18", @"11/64", @"17", @"16", @"15", @"14", @"13", @"3/16", @"12", @"11", @"10", @"9", @"8", @"7", @"13/64", @"6", @"5", @"4", @"3", @"7/32", @"2", @"1", @"A", @"15/64", @"B", @"C", @"D", @"1/4", @"E", @"F", @"G", @"17/64", @"H", @"I", @"J", @"K", @"9/32", @"L", @"M", @"19/64", @"N", @"5/16", @"O", @"P", @"21/64", @"Q", @"R", @"11/32", @"S", @"T", @"23/64", @"U", @"3/8", @"V", @"W", @"25/64", @"X", @"Y", @"13/32", @"Z", @"27/64", @"7/16", @"29/64", @"15/32", @"31/64", @"1/2", @"33/64", @"17/32", @"35/64", @"9/16", @"37/64", @"19/32", @"39/64", @"5/8", @"41/64", @"21/32", @"43/64", @"11/16", @"45/64", @"23/32", @"47/64", @"3/4", @"49/64", @"25/32", @"51/64", @"13/16", @"53/64", @"27/32", @"55/64", @"7/8", @"57/64", @"29/32", @"59/64", @"15/16", @"61/64", @"31/32", @"63/64", nil];

    NSDictionary *sizeDict = [NSDictionary dictionaryWithObjectsAndKeys:@".0135", @"80", @".0145", @"79", @".0160", @"78", @".0180", @"77", @".0200", @"76", @".0210", @"75", @".0225", @"74", @".0240", @"73", @".0250", @"72", @".0260", @"71", @".0280", @"70", @".0292", @"69", @".0310", @"68", @".0320", @"67", @".0330", @"66", @".0350", @"65", @".0360", @"64", @".0370", @"63", @".0380", @"62", @".0390", @"61", @".0400", @"60", @".0410", @"59", @".0420", @"58", @".0430", @"57", @".0465", @"56", @".0520", @"55", @".0550", @"54", @".0595", @"53", @".0635", @"52", @".0670", @"51", @".0700", @"50", @".0730", @"49", @".0760", @"48", @".0785", @"47", @".0810", @"46", @".0820", @"45", @".0860", @"44", @".0890", @"43", @".0935", @"42", @".0960", @"41", @".0980", @"40", @".0995", @"39", @".1015", @"38", @".1040", @"37", @".1065", @"36", @".1100", @"35", @".1110", @"34", @".1130", @"33", @".1160", @"32", @".1200", @"31", @".1285", @"30", @".1360", @"29", @".1405", @"28", @".1440", @"27", @".1470", @"26", @".1495", @"25", @".1520", @"24", @".1540", @"23", @".1570", @"22", @".1590", @"21", @".1610", @"20", @".1660", @"19", @".1695", @"18", @".1730", @"17", @".1770", @"16", @".1800", @"15", @".1820", @"14", @".1850", @"13", @".1890", @"12", @".1910", @"11", @".1935", @"10", @".1960", @"9", @".1990", @"8", @".2010", @"7", @".2040", @"6", @".2055", @"5", @".2090", @"4", @".2130", @"3", @".2210", @"2", @".2280", @"1", @".2340", @"A", @".2380", @"B", @".2420", @"C", @"2460", @"D", @".2500", @"E", @".2570", @"F", @".2610", @"G", @".2660", @"H", @".2720", @"I", @".2770", @"J", @".2810", @"K", @".2900", @"L", @".2950", @"M", @".3020", @"N", @".3160", @"O", @".3230", @"P", @".3320", @"Q", @".3390", @"R", @".3480", @"S", @".3580", @"T", @".3680", @"U", @".3770", @"V", @".3860", @"W", @".3970", @"X", @".4040", @"Y", @".4130", @"Z", nil];
    NSMutableArray *sizeStringArray = [NSMutableArray arrayWithCapacity:128];
    NSMutableArray *valueNumberArray = [NSMutableArray arrayWithCapacity:128];
    NSMutableArray *metricNumberArray = [NSMutableArray arrayWithCapacity:128];
    NSMutableArray *sixtyFoursSizeStringArray = [NSMutableArray arrayWithCapacity:64];
    NSMutableArray *sixtyFoursValueNumberArray = [NSMutableArray arrayWithCapacity:64];
    NSMutableArray *sixtyFoursMetricNumberArray = [NSMutableArray arrayWithCapacity:64];
    NSNumber *dValue;
    NSNumber *metric;
    float mm = (float) .039705;
    for (NSString *dsize in drillArray) {
        NSArray *dArray = [dsize componentsSeparatedByString:@"/"];
        NSInteger dArraySize = [dArray count];
        if (dArraySize == 1) {
            NSString *dKey = [dArray objectAtIndex:0];
            NSString *dValueStr = [sizeDict objectForKey:dKey];
            dValue = [NSNumber numberWithFloat:[dValueStr floatValue]];
            [sizeDict objectForKey:dKey];
            [sizeStringArray addObject:dKey];
            [valueNumberArray addObject:dValue];
        } else {
            [sizeStringArray addObject:dsize];
            [sixtyFoursSizeStringArray addObject:dsize];
            CGFloat num = [[dArray objectAtIndex:0] floatValue];
            CGFloat dem = [[dArray objectAtIndex:1] floatValue];
            CGFloat demValue = num / dem;
            dValue = [NSNumber numberWithFloat:demValue];
            [valueNumberArray addObject:[dValue stringValue]];
            [sixtyFoursValueNumberArray addObject:[dValue stringValue]];
            metric = [NSNumber numberWithFloat:[dValue floatValue] / mm];
            [sixtyFoursMetricNumberArray addObject:metric];
        }
        metric = [NSNumber numberWithFloat:[dValue floatValue] / mm];
        [metricNumberArray addObject:metric];
    }

    drillsComponent = sizeStringArray;
    valuesComponent = valueNumberArray;
    metricsComponent = metricNumberArray;

    sixtyFoursDrillsComponent = sixtyFoursSizeStringArray;
    sixtyFoursValuesComponent = sixtyFoursValueNumberArray;
    sixtyFoursMetricsComponent = sixtyFoursMetricNumberArray;

    [self.sizePicker layoutSubviews];
    [self updateDecimalLabel];
    [self updateFractionLabel];
    [self updateMetricLabel];
    self.bannerIsVisible = YES;

    mmInchButton.layer.cornerRadius = 8;
    mmInchButton.layer.masksToBounds = YES;
//	[self.mmInchButton setButtonColor:[UIColor colorWithRed:160/255.0 green:170/255.0 blue:200/255.0 alpha:1.0]];


    mmSizeButton.layer.cornerRadius = 8;
    mmSizeButton.layer.masksToBounds = YES;
//	[self.mmSizeButton setButtonColor:[UIColor colorWithRed:160/255.0 green:170/255.0 blue:200/255.0 alpha:1.0]];
}

- (void)viewDidUnload {
    [self setSizePicker:nil];
    [self setAdBannerView:nil];
    [self setMmInchButton:nil];
    [self setMmSizeButton:nil];
    [self setSixtyFoursOnly:nil];
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
        return (interfaceOrientation == UIDeviceOrientationPortrait);
    } else {
        return NO;
    }
}

#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
//    NSLog(@"drillsComponent: %d", [drillsComponent count]);
    if (sixtyFoursOnly.isOn) {
        switch (component) {
            case kSizes:
                return [sixtyFoursDrillsComponent count];
            case kValues:
                return [sixtyFoursValuesComponent count];
            case kMetrics:
                return [sixtyFoursMetricsComponent count];
            default:
                return 0;
        }
    } else {
        switch (component) {
            case kSizes:
                return [drillsComponent count];
            case kValues:
                return [valuesComponent count];
            case kMetrics:
                return [metricsComponent count];
            default:
                return 0;
        }
    }
}

#pragma mark Picker Delegate Methods
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
//    CGRect aRect = [pickerView bounds];
//    CGFloat aSize = pickerView.bounds.size.width;
//    return aSize / 3;
    CGFloat aSize;
    switch (component) {
        case kSizes:
            aSize = (CGFloat) 100;
        case kValues:
            aSize = (CGFloat) 90;
        case kMetrics:
            aSize = (CGFloat) 100;
        default:
            aSize = (CGFloat) 100;
    }
    return aSize;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (component) {
        case kSizes:
        {
            [pickerView selectRow:row inComponent:kValues animated:YES];
            [pickerView selectRow:row inComponent:kMetrics animated:YES];
            break;
        }
        case kValues:
            [pickerView selectRow:row inComponent:kSizes animated:YES];
            [pickerView selectRow:row inComponent:kMetrics animated:YES];
            break;
        case kMetrics:
        {
            [pickerView selectRow:row inComponent:kValues animated:YES];
            [pickerView selectRow:row inComponent:kSizes animated:YES];
            break;
        }
    }
}

// TODO: set fractionals to red.
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *formattedNumberString = @"NaN";
    if (sixtyFoursOnly.isOn) {
        switch (component) {
            case kSizes:
            {
                formattedNumberString = [sixtyFoursDrillsComponent objectAtIndex:(NSUInteger) row];
                break;
            }
            case kValues:
            {
                NSNumber *decValue = [sixtyFoursValuesComponent objectAtIndex:(NSUInteger) row];
                formattedNumberString = [[NSString stringWithFormat:@"%.4lf", [decValue floatValue]] substringFromIndex:1];
                break;
            }
            case kMetrics:
            {
                NSNumber *metric = [sixtyFoursMetricsComponent objectAtIndex:(NSUInteger) row];
                formattedNumberString = [NSString stringWithFormat:@"%.4lf", [metric floatValue]];
                break;
            }
        }
    } else {
        switch (component) {
            case kSizes:
            {
                formattedNumberString = [drillsComponent objectAtIndex:(NSUInteger) row];
                break;
            }
            case kValues:
            {
                NSNumber *decValue = [valuesComponent objectAtIndex:(NSUInteger) row];
                formattedNumberString = [[NSString stringWithFormat:@"%.4lf", [decValue floatValue]] substringFromIndex:1];
                break;
            }
            case kMetrics:
            {
                NSNumber *metric = [metricsComponent objectAtIndex:(NSUInteger) row];
                formattedNumberString = [NSString stringWithFormat:@"%.4lf", [metric floatValue]];
                break;
            }
        }
    }
    //    NSLog(@"titleForRow: %@", formattedNumberString);
    return formattedNumberString;
}

//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
//	{
//		UILabel* tView = (UILabel*)view;
//		if (!tView){
//			tView = [[UILabel alloc] init];
//			tView.font = [UIFont systemFontOfSize:16];
//            // Setup label properties - frame, font, colors etc
//		}
//		tView.text = @"NaN";
//		// Fill the label text here
//		return tView;
//	}
//	
#pragma mark - image View Controller

- (void)imageViewControllerDidFinish:(ImageViewController *)controller {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.imagePopoverController dismissPopoverAnimated:YES];
        self.imagePopoverController = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imagePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
    id aController = [segue destinationViewController];
    [aController setDelegate:self];

    UIUserInterfaceIdiom idiom = [[UIDevice currentDevice] userInterfaceIdiom];
    if (idiom == UIUserInterfaceIdiomPad) {
        UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *) segue popoverController];
        self.imagePopoverController = popoverController;
        popoverController.delegate = self;
    }
//    }
}

- (IBAction)togglePopover:(id)sender {
    if (self.imagePopoverController) {
        [self.imagePopoverController dismissPopoverAnimated:YES];
        self.imagePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}

- (IBAction)sixtyFoursChanged:(id)sender {
    NSString *foundAValue;
    NSInteger foundAIndex = -1;
    NSInteger sIndex = 0;

    NSInteger theRow = [self.sizePicker selectedRowInComponent:0];
    if (sixtyFoursOnly.isOn) {
        NSLog(@"64s is On");
        // This means we were in the big array and possibly on a value which doesn't
        // exists in the small array. So lookup the value in the big array and search
        // back for the nearest sixtyFour value locate theValue in the small array
        NSString *searchValue = [drillsComponent objectAtIndex:(NSUInteger) theRow];
        NSLog(@"Looking for %@ in the big array", searchValue);
        for (NSString *aValue in drillsComponent) {
            NSArray *vArray = [aValue componentsSeparatedByString:@"/"];
            if (vArray.count == 2) {
                foundAValue = aValue;
                foundAIndex = sIndex;
                NSLog(@"Found %@ at %d", foundAValue, foundAIndex);
            }
            if ([aValue isEqualToString:searchValue]) {
                NSLog(@"Found search value: %@", searchValue);
                break;
            }
            sIndex++;
        }
        if (foundAIndex != -1) {
            NSLog(@"Looking for %@ in the small array", foundAValue);

            // We found a good smaller value
            // Now search for it in the small array and scroll to it
            // Reset counters
            foundAIndex = -1;
            sIndex = 0;
            for (NSString *aValue in sixtyFoursDrillsComponent) {
                if ([aValue isEqualToString:foundAValue]) {
                    foundAIndex = sIndex;
                    NSLog(@"Found %@ at %d", foundAValue, foundAIndex);
                    break;
                }
                sIndex++;
            }
            if (foundAIndex != -1) {
				[self.sizePicker reloadAllComponents];
                [_sizePicker selectRow:foundAIndex inComponent:0 animated:YES];
                [_sizePicker selectRow:foundAIndex inComponent:1 animated:YES];
                [_sizePicker selectRow:foundAIndex inComponent:2 animated:YES];
            }
        }
    } else {
        NSLog(@"64s is Off");
        // we were in the small array so find the row in the big array
        NSString *searchValue = [sixtyFoursDrillsComponent objectAtIndex:(NSUInteger) theRow];
        NSLog(@"Looking for %@ in the big array", searchValue);
        for (NSString *aValue in drillsComponent) {
            if ([aValue isEqualToString:searchValue]) {
                foundAIndex = sIndex;
                NSLog(@"Found %@ at %d big:%@", searchValue, foundAIndex, [drillsComponent objectAtIndex:(NSUInteger) sIndex]);
                break;
            }
            sIndex++;
        }
        if (foundAIndex != -1) {
			[self.sizePicker reloadAllComponents];
            [_sizePicker selectRow:foundAIndex inComponent:0 animated:YES];
            [_sizePicker selectRow:foundAIndex inComponent:1 animated:YES];
            [_sizePicker selectRow:foundAIndex inComponent:2 animated:YES];
        }
    }
    NSLog(@"------------------------");
}

#pragma mark - Banner Delegate
- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    if (!self.bannerIsVisible) {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
        // Assumes the banner view is just off the bottom of the screen.
        banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height);
        [UIView commitAnimations];
        self.bannerIsVisible = YES;
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    if (self.bannerIsVisible) {
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        // Assumes the banner view is placed at the bottom of the screen.
        banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
        [UIView commitAnimations];
        self.bannerIsVisible = NO;
        [TestFlight passCheckpoint:@"iAd Banner Failed"];
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    NSLog(@"Banner view is beginning an ad action");
    BOOL shouldExecuteAction = YES; //[self allowActionToRun]; // your application implements this method
    if (!willLeave && shouldExecuteAction) {
        // insert code here to suspend any services that might conflict with the advertisement
    }
    return shouldExecuteAction;
}
@end
