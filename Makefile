ifeq ($(RESPRING),0)
	INSTALL_TARGET_PROCESSES = Preferences
else
	INSTALL_TARGET_PROCESSES = SpringBoard
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Quanta

Quanta_FILES = $(wildcard *.x)
Quanta_FRAMEWORKS = IOKit

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
