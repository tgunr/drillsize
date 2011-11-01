//
//  FlipsideViewController.m
//  DrillSize
//
//  Created by Dave Carlton on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"

@implementation FlipsideViewController

@synthesize delegate;
@synthesize mainViewController;

- (void)awakeFromNib
{
	self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    UIDevice * aDevice = [UIDevice currentDevice];
    UIUserInterfaceIdiom idiom = [aDevice userInterfaceIdiom];
    // Return YES for supported orientations
	if (idiom == UIUserInterfaceIdiomPhone) {
	    return YES; //(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return NO;
	}
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end

@interface InchMMViewController (ViewHandlingMethods)
- (void)pickImageNamed:(NSString *)name;
@end

@interface InchMMViewController (AutoscrollingMethods)
- (void)autoscrollTimerFired:(NSTimer *)timer;
- (void)legalizeAutoscrollDistance;
- (float)autoscrollDistanceForProximityToEdge:(float)proximity;
@end

@interface InchMMViewController (UtilityMethods)
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
@end

@implementation InchMMViewController
@synthesize imageView;
@synthesize imageScrollView;

- (IBAction)finish:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (IBAction)singleTap:(id)sender {
}

- (IBAction)doubleTap:(id)sender {
    
}

- (IBAction)pinch:(id)sender {
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageScrollView.minimumZoomScale=0.5;
    self.imageScrollView.maximumZoomScale=6.0;
    self.imageScrollView.contentSize=CGSizeMake(1203, 203);
    self.imageScrollView.delegate = self;
}

- (void)viewDidUnload {
    [self setImageView:nil];
    [self setImageScrollView:nil];
    [super viewDidUnload];
}

#pragma mark Autoscrolling methods

- (float)autoscrollDistanceForProximityToEdge:(float)proximity {
    // the scroll distance grows as the proximity to the edge decreases, so that moving the thumb
    // further over results in faster scrolling.
    return ceilf((AUTOSCROLL_THRESHOLD - proximity) / 5.0);
}

- (void)legalizeAutoscrollDistance {
    // makes sure the autoscroll distance won't result in scrolling past the content of the scroll view
    float minimumLegalDistance = [imageScrollView contentOffset].x * -1;
    float maximumLegalDistance = [imageScrollView contentSize].width - ([imageScrollView frame].size.width + [imageScrollView contentOffset].x);
    autoscrollDistance = MAX(autoscrollDistance, minimumLegalDistance);
    autoscrollDistance = MIN(autoscrollDistance, maximumLegalDistance);
}

- (void)autoscrollTimerFired:(NSTimer*)timer {
    [self legalizeAutoscrollDistance];
    
    // autoscroll by changing content offset
    CGPoint contentOffset = [imageScrollView contentOffset];
    contentOffset.x += autoscrollDistance;
    [imageScrollView setContentOffset:contentOffset];
    
    // adjust thumb position so it appears to stay still
//    ThumbImageView *thumb = (ThumbImageView *)[timer userInfo];
//    [thumb moveByOffset:CGPointMake(autoscrollDistance, 0)];
}


#pragma mark TapDetectingImageViewDelegate methods

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint {
    // double tap zooms in
    float newScale = [imageScrollView zoomScale] * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [imageScrollView zoomToRect:zoomRect animated:YES];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint {
    // two-finger tap zooms out
    float newScale = [imageScrollView zoomScale] / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [imageScrollView zoomToRect:zoomRect animated:YES];
}


#pragma mark View handling methods

- (void)pickImageNamed:(NSString *)name {
    
    // first remove previous image view, if any
    [[imageScrollView viewWithTag:ZOOM_VIEW_TAG] removeFromSuperview];
    
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", name]];
    TapDetectingImageView *zoomView = [[TapDetectingImageView alloc] initWithImage:image];
    [zoomView setDelegate:self];
    [zoomView setTag:ZOOM_VIEW_TAG];
    [imageScrollView addSubview:zoomView];
    [imageScrollView setContentSize:[zoomView frame].size];
    
    // choose minimum scale so image width fits screen
    float minScale  = [imageScrollView frame].size.width  / [zoomView frame].size.width;
    [imageScrollView setMinimumZoomScale:minScale];
    [imageScrollView setZoomScale:minScale];
    [imageScrollView setContentOffset:CGPointZero];
}


#pragma mark Utility methods

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [imageScrollView frame].size.height / scale;
    zoomRect.size.width  = [imageScrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

@end

@implementation SizeMMViewController

@synthesize imageView;
@synthesize imageScrollView;



- (IBAction)finish:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}


@end
