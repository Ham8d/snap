#import "substrate.h"
#import <objc/runtime.h>
#import <objc/message.h>

// تعريف الدوال الأساسية من Foundation يدوياً لتجنب الـ Headers الثقيلة
void NSLog(NSString *format, ...);

// تعريف الكلاسات الهدف في سناب
// ملاحظة: يجب التأكد من أسماء الكلاسات والدوال من ملف سناب الأصلي
// هذه أسماء شائعة في سناب، قد تحتاج لتعديلها حسب النسخة

@interface SUBSubscriptionManager : NSObject
@end

@interface SUBAppController : NSObject
@end

// دالة مساعدة للـ Hook
static BOOL isPremiumOverride(id self, SEL _cmd) {
    NSLog(@"[SnapFix] Hooked: isPremiumActive -> YES");
    return YES;
}

static void requestSubscriptionOverride(id self, SEL _cmd, void (^completion)(BOOL, id)) {
    NSLog(@"[SnapFix] Hooked: requestSubscriptionCodeWithCompletion -> Success");
    if (completion) {
        completion(YES, nil);
}

static void validateCodeOverride(id self, SEL _cmd, id code, void (^completion)(BOOL)) {
    NSLog(@"[SnapFix] Hooked: validateCode -> Valid");
    if (completion) {
        completion(YES);
}

static BOOL isSubscribedOverride(id self, SEL _cmd) {
    NSLog(@"[SnapFix] Hooked: SUBAppController.isSubscribed -> YES");
    return YES;
}

%ctor {
    NSLog(@"[SnapFix] Library Loaded!");

    // 1. Hook لـ SUBSubscriptionManager
    Class subMgrClass = objc_getClass("SUBSubscriptionManager");
    if (subMgrClass) {
        // Hook لدالة isPremiumActive
        Method isPremiumMethod = class_getInstanceMethod(subMgrClass, @selector(isPremiumActive));
        if (isPremiumMethod) {
            method_setImplementation(isPremiumMethod, (IMP)isPremiumOverride);
        }

        // Hook لدالة requestSubscriptionCodeWithCompletion:
        Method reqMethod = class_getInstanceMethod(subMgrClass, @selector(requestSubscriptionCodeWithCompletion:));
        if (reqMethod) {
            method_setImplementation(reqMethod, (IMP)requestSubscriptionOverride);
        }

        // Hook لدالة validateCode:completion:
        Method validateMethod = class_getInstanceMethod(subMgrClass, @selector(validateCode:completion:));
        if (validateMethod) {
            method_setImplementation(validateMethod, (IMP)validateCodeOverride);
        }
    }

    // 2. Hook لـ SUBAppController
    Class appCtrlClass = objc_getClass("SUBAppController");
    if (appCtrlClass) {
        Method isSubMethod = class_getInstanceMethod(appCtrlClass, @selector(isSubscribed));
        if (isSubMethod) {
            method_setImplementation(isSubMethod, (IMP)isSubscribedOverride);
        }
    }
}
