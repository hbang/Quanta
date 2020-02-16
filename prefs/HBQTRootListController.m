#import "HBQTRootListController.h"
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Preferences/PSSpecifier.h>
#import "BatteryProperties.h"

@interface BCBatteryDeviceController : NSObject

+ (instancetype)sharedInstance;

@end

@implementation HBQTRootListController {
	NSNumber *_internalDesignCapacity;
	NSNumber *_internalActualCapacity;
	NSNumber *_internalCycleCount;
	BOOL _externalIsConnected;
	NSString *_externalModel;
	NSNumber *_externalDesignCapacity;
	NSNumber *_externalActualCapacity;
	NSNumber *_externalCycleCount;

	NSNumberFormatter *_decimalNumberFormatter;

	PSSpecifier *_externalBatteryDisconnectedSpecifier;
	PSSpecifier *_externalBatteryConnectedSpecifier;
	NSArray <PSSpecifier *> *_externalBatterySpecifiers;
}

#pragma mark - Constants

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

+ (NSString *)hb_shareText {
	return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"SHARE_TEXT", @"Root", [NSBundle bundleForClass:self.class], @"Default text for sharing the tweak. %@ is the device type (ie, iPhone)."), [UIDevice currentDevice].localizedModel];
}

+ (NSURL *)hb_shareURL {
	return [NSURL URLWithString:@"https://chariz.com/get/quanta"];
}

#pragma mark - UIViewController

- (instancetype)init {
	self = [super init];

	if (self) {
		HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
		appearanceSettings.tintColor = [UIColor colorWithRed:232.f / 255.f green:79.f / 255.f blue:61.f / 255.f alpha:1];
		self.hb_appearanceSettings = appearanceSettings;

		_decimalNumberFormatter = [[NSNumberFormatter alloc] init];
		_decimalNumberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		_decimalNumberFormatter.maximumFractionDigits = 0;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:@"HBQTPowerSupplyChangeNotification" object:nil];
	}

	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self _configureSpecifiersAnimated:NO];
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];
	[self _configureSpecifiersAnimated:YES];
}

- (void)_configureSpecifiersAnimated:(BOOL)animated {
	NSDictionary <NSString *, id> *internalBatteryProperties = getInternalBatteryProperties();
	NSDictionary <NSString *, id> *externalBatteryProperties = getExternalBatteryProperties();

	_internalDesignCapacity = internalBatteryProperties[@"DesignCapacity"];
	_internalActualCapacity = internalBatteryProperties[@"AppleRawMaxCapacity"];
	_internalCycleCount = internalBatteryProperties[@"CycleCount"];
	_externalIsConnected = ((NSNumber *)externalBatteryProperties[@"Is Present"]).boolValue;
	_externalModel = externalBatteryProperties[@"Model Number"];
	_externalDesignCapacity = externalBatteryProperties[@"Max Capacity"];
	_externalActualCapacity = externalBatteryProperties[@"Nominal Capacity"];
	_externalCycleCount = externalBatteryProperties[@"CycleCount"];
}

- (NSString *)getInternalDesignCapacity {
	return _internalDesignCapacity == nil
		? @"—"
		: [NSString stringWithFormat:@"%@ mAh", [_decimalNumberFormatter stringFromNumber:_internalDesignCapacity]];
}

- (NSString *)getInternalActualCapacity {
	return _internalActualCapacity == nil
		? @"—"
		: [NSString stringWithFormat:@"%@ mAh", [_decimalNumberFormatter stringFromNumber:_internalActualCapacity]];
}

- (NSString *)getInternalCycleCount {
	return _internalCycleCount == nil
		? @"—"
		: [_decimalNumberFormatter stringFromNumber:_internalCycleCount];
}

- (NSString *)getExternalModel {
	return _externalModel == nil
		? @"—"
		: _externalModel;
}

- (NSString *)getExternalDesignCapacity {
	return _externalDesignCapacity == nil
		? @"—"
		: [NSString stringWithFormat:@"%@ mAh", [_decimalNumberFormatter stringFromNumber:_externalDesignCapacity]];
}

- (NSString *)getExternalActualCapacity {
	return _externalActualCapacity == nil
		? @"—"
		: [NSString stringWithFormat:@"%@ mAh", [_decimalNumberFormatter stringFromNumber:_externalActualCapacity]];
}

- (NSString *)getExternalCycleCount {
	return _externalCycleCount == nil
		? @"—"
		: [_decimalNumberFormatter stringFromNumber:_externalCycleCount];
}

@end
