include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Quanta
Quanta_FILES = $(wildcard *.m) $(wildcard *.x)
Quanta_INSTALL_PATH = /Library/PreferenceBundles
Quanta_FRAMEWORKS = IOKit
Quanta_PRIVATE_FRAMEWORKS = Preferences
Quanta_EXTRA_FRAMEWORKS = CepheiPrefs CydiaSubstrate
Quanta_CFLAGS = -I..

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Quanta.plist$(ECHO_END)
