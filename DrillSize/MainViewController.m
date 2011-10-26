//
//  MainViewController.m
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"

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
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (component) {
        case kDecimals:
            return [[decimalComponent objectAtIndex:(NSUInteger) row] stringValue];
        case kFractions:
            return [fractionsComponent objectAtIndex:(NSUInteger) row];
        case kMetric:
            return [[metricComponent objectAtIndex:(NSUInteger) row] stringValue];
        default:
            return @"";
    }
}

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
