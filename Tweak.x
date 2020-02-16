@import UIKit;
#import <UIKit/UIApplication+Private.h>
#import <UIKit/UIStatusBar.h>
#import "BatteryProperties.h"

@interface UIStatusBar ()

- (void)forceUpdateData:(BOOL)animated;

@end

@interface _UIStatusBarDataBatteryEntry : NSObject

@property (nonatomic) NSInteger capacity;
@property (nonatomic, copy) NSString *detailString;
@property (nonatomic) BOOL prominentlyShowsDetailString;
@property (nonatomic) BOOL saverModeActive;
@property (nonatomic) NSInteger state;

@end

@interface BCBatteryDevice : NSObject

@property (getter=isInternal, nonatomic) BOOL internal;
@property (getter=isPowerSource, nonatomic) BOOL powerSource;
@property (nonatomic, getter=isCharging) BOOL charging;
@property (nonatomic) NSInteger percentCharge;

@end

@interface BCBatteryDeviceController : NSObject

+ (instancetype)sharedInstance;

- (NSArray <BCBatteryDevice *> *)connectedDevices;

@end

%hook _UIStatusBarData

- (void)setMainBatteryEntry:(_UIStatusBarDataBatteryEntry *)mainBatteryEntry {
	BCBatteryDeviceController *batteryDeviceController = [%c(BCBatteryDeviceController) sharedInstance];
	NSArray <BCBatteryDevice *> *devices = batteryDeviceController.connectedDevices;

	BCBatteryDevice *internalDevice = nil, *externalDevice = nil;
	for (BCBatteryDevice *device in devices) {
		if (device.isInternal && internalDevice == nil) {
			internalDevice = device;
		} else if (!device.isInternal && device.isPowerSource && externalDevice == nil) {
			externalDevice = device;
		}
		if (internalDevice != nil && externalDevice != nil) {
			break;
		}
	}

	if (externalDevice != nil) {
		static NSNumberFormatter *numberFormatter;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			numberFormatter = [[NSNumberFormatter alloc] init];
			numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
			numberFormatter.maximumFractionDigits = 0;
			numberFormatter.multiplier = @1;
		});

		NSDictionary <NSString *, id> *internalSource = getInternalBatteryProperties();
		NSDictionary <NSString *, id> *externalSource = getExternalBatteryProperties();

		// Use the available capacity readings of the phone and battery case to determine which portion
		// of the percentage is “owned” by each device.
		// https://www.apple.com/legal/more-resources/docs/apple-product-information-sheet.pdf
		double internalCapacityMAh = ((NSNumber *)internalSource[@"AppleRawMaxCapacity"]).doubleValue;
		double externalCapacityMAh = ((NSNumber *)externalSource[@"Nominal Capacity"]).doubleValue;

		double externalBatteryPortion;
		if (internalCapacityMAh == 0.0 || externalCapacityMAh == 0.0) {
			// If a reading is invalid, just make the portion fixed at 33%.
			externalBatteryPortion = 1.0 / 3.0;
		} else {
			externalBatteryPortion = externalCapacityMAh / (internalCapacityMAh + externalCapacityMAh);
		}

		NSInteger capacity = (internalDevice.percentCharge * (1.0 - externalBatteryPortion))
			+ (externalDevice.percentCharge * externalBatteryPortion);
		mainBatteryEntry.capacity = capacity;
		mainBatteryEntry.state = externalDevice.isCharging ? 1 : 0;
		mainBatteryEntry.detailString = [NSString stringWithFormat:@"%@ + %@",
			[numberFormatter stringFromNumber:@(internalDevice.percentCharge)],
			[numberFormatter stringFromNumber:@(externalDevice.percentCharge)]];
	}

	%orig;
}

%end

// TODO: The status bar force updating stuff is kinda not the right way to do it. SpringBoard has
// good stuff for this. We should switch to it.
static NSTimer *statusBarUpdateTimer = nil;
static NSMutableSet *statusBars;

%hook BCBatteryDeviceController

- (void)_handlePSChange {
	%orig;

	// This can fire multiple times causing awkward animations, so debounce is needed.
	if (statusBarUpdateTimer == nil) {
		statusBarUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer *timer) {
			for (UIStatusBar *statusBar in statusBars) {
				[statusBar forceUpdateData:YES];
			}
			statusBarUpdateTimer = nil;
		}];
	}
}

%end

%hook UIStatusBar_Base

- (instancetype)_initWithFrame:(CGRect)frame showForegroundView:(BOOL)showForegroundView wantsServer:(BOOL)wantsServer inProcessStateProvider:(id)inProcessStateProvider {
	self = %orig;
	if (self) {
		[statusBars addObject:self];
	}
	return self;
}

- (void)dealloc {
	[statusBars removeObject:self];
	%orig;
}

%end

%ctor {
	statusBars = [NSMutableSet set];
}
