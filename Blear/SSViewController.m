//
//  SSViewController.m
//  Blear
//
//  Created by Sindre Sorhus on 9/15/13.
//  Copyright (c) 2017 Sindre Sorhus. All rights reserved.
//

#import "SSViewController.h"
#import "FDTakeController.h"
#import "UIImageEffects.h"
#import "UIImage+UIViewCapture.h"
#import "PerformSelectorWithDebounce.h"
#import "IIDelayedAction.h"
#import "NZAssetsLibrary.h"
#import "JGProgressHUD.h"


#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define SLOW_DEVICE IS_IPAD


int uniqRand(int upperBound, int avoid) {
	if (avoid < upperBound) {
		--upperBound;
	}

	int number = arc4random_uniform(upperBound);
	if (number >= avoid) {
		++number;
	}

	return number;
}


@interface SSViewController () <FDTakeDelegate, JGProgressHUDDelegate>

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) FDTakeController *takeController;
@property (nonatomic) double blurAmount;
@property (nonatomic, assign) int prevRandNum;
@property (nonatomic, strong) NSArray *stockImages;

- (UIImage*)blurImage:(double)blurAmount;

@end

@implementation SSViewController {
	IIDelayedAction* _delayedAction;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {

	}
	return self;
}

- (NSArray*)getBundledPhotos {
	NSString *bundledPhotosPath = [[NSBundle mainBundle] pathForResource:@"bundled-photos" ofType:nil];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundledPhotosPath error:nil];
	return [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"]];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_prevRandNum = 0;
	_stockImages = [self getBundledPhotos];

	// This is to ensure that it always ends up with the current blur amount when the slider stops
	// since we're using async_dispatch the order of events aren't serial
	_delayedAction = [IIDelayedAction delayedAction:^{} withDelay:0.2];
	_delayedAction.onMainThread = NO;

	_takeController = [[FDTakeController alloc] init];
	_takeController.delegate = self;
	_takeController.allowsEditingPhoto = YES;

	// Create back bg
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.view.frame.size.width, self.view.frame.size.height), NO, 0);
	UIBezierPath* p =
	[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	[[UIColor blackColor] setFill];
	[p fill];
	UIImage* blackFill = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	_prevRandNum = uniqRand((int)_stockImages.count, 9999999); // Ugh...
	_imageView = [[UIImageView alloc] initWithImage:blackFill];
	_imageView.contentMode = UIViewContentModeScaleAspectFill;
	_imageView.clipsToBounds = YES;
	_imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	[self.view addSubview:_imageView];

	UIBarButtonItem *pickImageButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btn-pick"] style:UIBarButtonItemStylePlain target:self action:@selector(pickImage)];
	pickImageButton.width = 20;

	int SLIDER_MARGIN = 120;
	_slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - SLIDER_MARGIN, self.view.frame.size.height)];
	_slider.minimumValue = 10;
	_slider.maximumValue = 100;
	_slider.value = _blurAmount = 50;
	_slider.continuous = YES;
	[_slider setThumbImage:[UIImage imageNamed:@"slider-thumb"] forState:UIControlStateNormal];
	_slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[_slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *sliderAsToolbarItem = [[UIBarButtonItem alloc] initWithCustomView:_slider];

	UIBarButtonItem *saveImageButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btn-save"] style:UIBarButtonItemStylePlain target:self action:@selector(saveImage:)];
	saveImageButton.width = 20;

	int TOOLBAR_HEIGHT = IS_IPAD ? 80 : 70;
	UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - TOOLBAR_HEIGHT, self.view.frame.size.width, TOOLBAR_HEIGHT)];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	toolbar.alpha = 0.6;
	toolbar.tintColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1];

	// Remove background
	[toolbar setBackgroundImage:[UIImage new]
				  forToolbarPosition:UIBarPositionAny
						  barMetrics:UIBarMetricsDefault];
	[toolbar setShadowImage:[UIImage new]
			  forToolbarPosition:UIToolbarPositionAny];

	// Gradient background
	int GRADIENT_PADDING = 40;
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = CGRectMake(0, -GRADIENT_PADDING, toolbar.frame.size.width, toolbar.frame.size.height + GRADIENT_PADDING);
	gradient.colors = @[(id)[UIColor clearColor].CGColor,
					   (id)[[UIColor blackColor] colorWithAlphaComponent:0.1].CGColor,
					   (id)[[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor,
					   (id)[[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor];
	[toolbar.layer addSublayer:gradient];

	UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	toolbar.items = @[pickImageButton, flexible, sliderAsToolbarItem, flexible, saveImageButton];

	[self.view addSubview:toolbar];

	// Important that this is here at the end for the fading to work
	[self changeImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", @"bundled-photos", _stockImages[_prevRandNum]]]];
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)pickImage {
	[_takeController takePhotoOrChooseFromLibrary];
}

- (UIImage*)blurImage:(double)blurAmount {
	return [UIImageEffects
			imageByApplyingBlurToImage:_sourceImage
			withRadius:blurAmount * (IS_IPHONE_6P? 0.8 : 1.2)
			tintColor:[UIColor colorWithWhite:1.0 alpha:MAX(0.0, MIN(0.25, blurAmount * 0.004))]
			saturationDeltaFactor:MAX(1.0, MIN(2.8, blurAmount * (IS_IPAD ? 0.035 : 0.045)))
			maskImage:nil];
}

- (void)updateImage {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		UIImage* tmp = [self blurImage:_blurAmount];

		dispatch_async(dispatch_get_main_queue(), ^{
			_imageView.image = tmp;
		});
	});
}

- (void)updateImageDebounced {
	[self performSelector:@selector(updateImage) withDebounceDuration:(SLOW_DEVICE ? 0.1 : 0.06)];
}

- (void)sliderChanged:(UISlider *)sender {
	_blurAmount = sender.value;

	[self updateImageDebounced];

	[_delayedAction action:^{
		[self updateImage];
	}];
}

- (void)saveImage:(UIBarButtonItem *)button {
	button.enabled = NO;
	// Rewrap the image as PNG
	UIImage *pngImage = [UIImage imageWithData:UIImagePNGRepresentation(_imageView.image)];

	NZAssetsLibrary *assetsLibrary = [NZAssetsLibrary defaultAssetsLibrary];

	[assetsLibrary saveImage:pngImage toAlbum:@"Blear" withCompletion:^(NSError *err) {
		button.enabled = YES;

		JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
		HUD.indicatorView = nil;
		HUD.animation = [JGProgressHUDFadeZoomAnimation animation];

		if (err) {
			HUD.textLabel.text = err.localizedDescription;
		} else {
			HUD.indicatorView = [[JGProgressHUDImageIndicatorView alloc] initWithImage:[UIImage imageNamed:@"hud-saved"]];
			HUD.indicatorView.tintColor = [UIColor blackColor];
		}

		[HUD showInView:self.view];
		[HUD dismissAfterDelay:0.8];

		// Only on first save
		if ([[NSUserDefaults standardUserDefaults] valueForKey:@"firstSave"] == NULL) {
			[[NSUserDefaults standardUserDefaults] setValue:@"not" forKey:@"firstSave"];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1), dispatch_get_main_queue(), ^(void) {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Changing Wallpaper"
                                                                                message:@"In the Photos app go to the wallpaper you just saved, tap the action button on the bottom left and choose \"Use as Wallpaper\"."
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* coolAction = [UIAlertAction actionWithTitle:@"Cool"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:nil];
                
                [alert addAction:coolAction];
                
                [self presentViewController:alert animated:YES completion:nil];
            });
		}
	}];
}

- (void)changeImage:(UIImage *)photo {
	UIImageView *tmp = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:_imageView]];
	[self.view insertSubview:tmp belowSubview:_slider.superview]; // below the toolbar

	_imageView.image = photo;
	_sourceImage = [[UIImage alloc] imageWithView:_imageView];
	[self updateImageDebounced];

	// The delay here is important so it has time to blur the image before we start fading
	[UIView animateWithDuration:0.6 delay:(SLOW_DEVICE ? 0.4 : 0.1) options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
		tmp.alpha = 0;
	} completion:^(BOOL finished) {
		if (finished) {
			[tmp removeFromSuperview];
		}
	}];
}

- (void)randomImage {
	_prevRandNum = uniqRand((int)_stockImages.count - 1, _prevRandNum);
	[self changeImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", @"bundled-photos", _stockImages[_prevRandNum]]]];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if (motion == UIEventSubtypeMotionShake) {
		[self randomImage];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info {
	[self changeImage:photo];
}

@end
