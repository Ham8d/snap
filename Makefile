TARGET := :iphone:16.5:2.0
ARCHS := arm64 arm64e
INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

# اسم الموديول
MY_LIB_NAME = SnapSubscriptionFix

# الملفات المصدر
SnapSubscriptionFix_FILES = main.m
SnapSubscriptionFix_FRAMEWORKS = Foundation UIKit
SnapSubscriptionFix_CFLAGS = -fobjc-arc -O2 -fvisibility=hidden
SnapSubscriptionFix_LDFLAGS = -install_name @executable_path/../Frameworks/libSnapSubscriptionFix.dylib

include $(THEOS)/makefiles/common.mk

include $(THEOS_MAKE_PATH)/library.plist

# بعد التجميع، نستخدم ldid لتوقيع الملف
after-install::
	install_executable
