export PACKAGE_VERSION := 3.0

ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := DayNightSwitch
DayNightSwitch_FILES += Tweak.xm
DayNightSwitch_FILES += DayNightSwitch.m
DayNightSwitch_CFLAGS += -fobjc-arc
DayNightSwitch_FRAMEWORKS = UIKit QuartzCore

# 关键新增：把 Resources 文件夹打包进插件
DayNightSwitch_BUNDLE_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard backboardd"

SUBPROJECTS += daynightswitch
include $(THEOS_MAKE_PATH)/aggregate.mk