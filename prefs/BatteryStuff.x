@interface BCBatteryDeviceController : NSObject

+ (instancetype)sharedInstance;

@end

%hook BCBatteryDeviceController

- (void)_handlePSChange {
	%orig;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"HBQTPowerSupplyChangeNotification" object:nil];
}

%end


%ctor {
	[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/BatteryCenter.framework"] load];
	%init;
	[%c(BCBatteryDeviceController) sharedInstance];
}
