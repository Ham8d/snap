#include <substrate.h>
#include <objc/runtime.h>
#include <objc/message.h>

// تعريف أنواع Objective-C الأساسية إذا لم تكن معرفة في substrate.h
#ifndef id
#define id struct objc_object *
#endif
#ifndef SEL
#define SEL struct objc_selector *
#endif
#ifndef BOOL
#define BOOL unsigned char
#endif
#ifndef YES
#define YES 1
#endif
#ifndef NO
#define NO 0
#endif

// تعريف دالة NSLog بسيطة لتجنب اعتماد كامل على Foundation Headers
void _NSLog(NSString *format, ...);

// تعريف الكلاسات الهدف (فقط لإعطاء شكلاً للكود، لا نحتاج لـ NSObject كاملاً هنا إذا استخدمنا id)
typedef struct objc_object {
    Class isa;
} *id;

typedef struct objc_class {
    struct objc_class *isa;
    struct objc_class *super_class;
    void *cache;
    void *vtable;
    struct objc_layout_info *info;
    struct objc_method_list **methodLists;
    struct objc_protocol_list **protocols;
    struct objc_ivar_list *ivarLists;
    struct objc_property_list **propertyLists;
} *Class;

// دوال الـ Hook

// 1. Hook لـ isPremiumActive
static BOOL isPremiumOverride(id self, SEL _cmd) {
    _NSLog(@"[SnapFix] isPremiumActive -> YES");
    return YES;
}

// 2. Hook لـ requestSubscriptionCodeWithCompletion:
// ملاحظة: نوع الكومبليشن قد يختلف، نستخدم void* لتجنب التعقيد أو نحدده بشكل عام
static void requestSubscriptionOverride(id self, SEL _cmd, void (*completion)(BOOL, id)) {
    _NSLog(@"[SnapFix] requestSubscriptionCodeWithCompletion -> Success");
    if (completion) {
        completion(YES, nil);
    }
}

// 3. Hook لـ validateCode:completion:
static void validateCodeOverride(id self, SEL _cmd, id code, void (*completion)(BOOL)) {
    _NSLog(@"[SnapFix] validateCode -> Valid");
    if (completion) {
        completion(YES);
    }
}

// 4. Hook لـ isSubscribed
static BOOL isSubscribedOverride(id self, SEL _cmd) {
    _NSLog(@"[SnapFix] isSubscribed -> YES");
    return YES;
}

// دالة التهيئة (Constructor)
__attribute__((constructor))
void initialize() {
    _NSLog(@"[SnapFix] Library Loaded!");

    // نستخدم objc_getClass للحصول على الكلاسات ديناميكياً
    Class subMgrClass = objc_getClass("SUBSubscriptionManager");
    if (subMgrClass) {
        Method isPremiumMethod = class_getInstanceMethod(subMgrClass, @selector(isPremiumActive));
        if (isPremiumMethod) {
            method_setImplementation(isPremiumMethod, (IMP)isPremiumOverride);
        }

        Method reqMethod = class_getInstanceMethod(subMgrClass, @selector(requestSubscriptionCodeWithCompletion:));
        if (reqMethod) {
            method_setImplementation(reqMethod, (IMP)requestSubscriptionOverride);
        }

        Method validateMethod = class_getInstanceMethod(subMgrClass, @selector(validateCode:completion:));
        if (validateMethod) {
            method_setImplementation(validateMethod, (IMP)validateCodeOverride);
        }
    }

    Class appCtrlClass = objc_getClass("SUBAppController");
    if (appCtrlClass) {
        Method isSubMethod = class_getInstanceMethod(appCtrlClass, @selector(isSubscribed));
        if (isSubMethod) {
            method_setImplementation(isSubMethod, (IMP)isSubscribedOverride);
        }
    }
}

// تعريف دالة NSLog الفعلية باستخدام objc_msgSend
// هذا يحل مشكلة عدم وجود Foundation.h
void _NSLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *logString = [[NSString alloc] initWithFormat:format arguments:args];
    NSLogv(logString, args);
    va_end(args);
}
