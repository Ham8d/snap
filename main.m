#include <substrate.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <stdio.h>
#include <stdlib.h>

// دالة طباعة بسيطة
void snapLog(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
}

// دوال الـ Hook

static BOOL isPremiumOverride(id self, SEL _cmd) {
    snapLog("[SnapFix] isPremiumActive -> YES");
    return YES;
}

// نستخدم مؤشر دالة عام للـ completion لتجنب مشاكل الأنواع في Swift/ObjC
static void requestSubscriptionOverride(id self, SEL _cmd, void *completion) {
    snapLog("[SnapFix] requestSubscriptionCodeWithCompletion -> Success");
    if (completion) {
        // نفترض أن الدالة تستقبل (BOOL success, id error)
        // نستخدم casting عام
        void (*callBack)(void*, BOOL, id) = (void (*)(void*, BOOL, id))completion;
        callBack(completion, YES, nil);
    }
}

static void validateCodeOverride(id self, SEL _cmd, id code, void *completion) {
    snapLog("[SnapFix] validateCode -> Valid");
    if (completion) {
        void (*callBack)(void*, BOOL) = (void (*)(void*, BOOL))completion;
        callBack(completion, YES);
    }
}

static BOOL isSubscribedOverride(id self, SEL _cmd) {
    snapLog("[SnapFix] isSubscribed -> YES");
    return YES;
}

__attribute__((constructor))
void initialize() {
    snapLog("[SnapFix] Library Loaded!");

    // 1. SUBSubscriptionManager
    Class subMgrClass = objc_getClass("SUBSubscriptionManager");
    if (subMgrClass) {
        Method m = class_getInstanceMethod(subMgrClass, @selector(isPremiumActive));
        if (m) method_setImplementation(m, (IMP)isPremiumOverride);
        
        m = class_getInstanceMethod(subMgrClass, @selector(requestSubscriptionCodeWithCompletion:));
        if (m) method_setImplementation(m, (IMP)requestSubscriptionOverride);

        m = class_getInstanceMethod(subMgrClass, @selector(validateCode:completion:));
        if (m) method_setImplementation(m, (IMP)validateCodeOverride);
    }

    // 2. SUBAppController
    Class appCtrlClass = objc_getClass("SUBAppController");
    if (appCtrlClass) {
        Method m = class_getInstanceMethod(appCtrlClass, @selector(isSubscribed));
        if (m) method_setImplementation(m, (IMP)isSubscribedOverride);
    }
}
