#import "BatteryProperties.h"

extern CFTypeRef IOPSCopyPowerSourcesInfo(void);
extern CFArrayRef IOPSCopyPowerSourcesList(CFTypeRef blob);
extern CFDictionaryRef IOPSGetPowerSourceDescription(CFTypeRef blob, CFTypeRef ps);

typedef mach_port_t io_service_t;
typedef mach_port_t io_object_t;
typedef io_object_t io_registry_entry_t;
typedef UInt32 IOOptionBits;

extern const mach_port_t kIOMasterPortDefault;
extern CFMutableDictionaryRef IOServiceMatching(const char *name);
extern io_service_t IOServiceGetMatchingService(mach_port_t masterPort, CFDictionaryRef matching);
extern kern_return_t IORegistryEntryCreateCFProperties(io_registry_entry_t entry, CFMutableDictionaryRef *properties, CFAllocatorRef allocator, IOOptionBits options);

static io_service_t internalBatteryService;

NSDictionary <NSString *, id> *getInternalBatteryProperties() {
	CFMutableDictionaryRef properties = nil;
	if (internalBatteryService != 0) {
		if (IORegistryEntryCreateCFProperties(internalBatteryService, &properties, NULL, kNilOptions) != KERN_SUCCESS) {
			return nil;
		}
	}
	return (NSDictionary <NSString *, id> *)CFBridgingRelease(properties);
}

NSDictionary <NSString *, id> *getExternalBatteryProperties() {
	CFTypeRef blob = IOPSCopyPowerSourcesInfo();
	CFArrayRef list = IOPSCopyPowerSourcesList(blob);
	NSDictionary <NSString *, id> *properties = nil;
	for (id source in (NSArray <id> *)list) {
		NSDictionary <NSString *, id> *description = (__bridge NSDictionary *)IOPSGetPowerSourceDescription(blob, source);
		if ([description[@"Accessory Category"] isEqualToString:@"Battery Case"]) {
			// Properties are released as a side-effect of releasing list below, so we need to copy.
			properties = [description copy];
			break;
		}
	}
	CFRelease(blob);
	CFRelease(list);
	return properties;
}

%ctor {
	internalBatteryService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBattery"));
}
