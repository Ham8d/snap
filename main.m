#include <substrate.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <stdio.h>
#include <stdlib.h>
#include <dispatch/dispatch.h>

// دالة للتصحيح (Debug)
void snapLog(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
}

// دالة بديلة ترجع نجاح دائماً (للدوال التي ترجع BOOL)
static BOOL returnTrue(id self, SEL _cmd) {
    snapLog("[SnapFix] Override BOOL: %s -> YES", sel_getName(_cmd));
    return YES;
}

// دالة بديلة تلغي التنفيذ (للدوال التي لا ترجع شيئاً void)
static void doNothing(id self, SEL _cmd) {
    snapLog("[SnapFix] Override VOID: %s -> Done", sel_getName(_cmd));
}

// دالة بديلة للـ Callbacks (تعيد النجاح فوراً)
static void completeSuccess(id self, SEL _cmd, void *completion) {
    snapLog("[SnapFix] Callback Success: %s", sel_getName(_cmd));
    if (completion) {
        // محاولة استدعاء الكومبليشن بنجاح
        // نستخدم نوع عام لتجنب الأخطاء
        void (*callBack)(void*, BOOL) = (void (*)(void*, BOOL))completion;
        callBack(completion, YES);
    }
}

__attribute__((constructor))
void initialize() {
    snapLog("[SnapFix] ===== STARTING FINAL FIX =====");

    // قائمة بأسماء الدوال الشائعة في سناب للتحقق من الاشتراك
    const char *checkMethods[] = {
        "isPremiumActive",
        "isSubscribed",
        "isValid",
        "hasActiveSubscription",
        "isPremium",
        "checkSubscriptionStatus",
        "validateSubscription",
        "verifyCode",
        "isValidCode"
    };
    int numCheckMethods = sizeof(checkMethods) / sizeof(checkMethods[0]);

    // قائمة بأسماء الدوال التي تعرض شاشة الطلب أو التنبيه
    const char *showMethods[] = {
        "showSubscriptionSheet",
        "presentSubscriptionView",
        "showPremiumAlert",
        "displaySubscriptionModal",
        "showPaywall",
        "presentPaywall",
        "showSubscriptionViewController",
        "showSubscriptionViewControllerAnimated:",
        "showSubscriptionViewController:animated:"
    };
    int numShowMethods = sizeof(showMethods) / sizeof(showMethods[0]);

    // قائمة بأسماء الكلاسات الشائعة في سناب
    const char *classNames[] = {
        "SUBSubscriptionManager",
        "SCSubscriptionManager",
        "SUBAppController",
        "SCAppController",
        "SUBPremiumManager",
        "SCPremiumManager",
        "SUBSubscriptionViewController",
        "SCSubscriptionViewController",
        "SUBPaywallManager",
        "SCPaywallManager",
        "AppDelegate"
    };
    int numClasses = sizeof(classNames) / sizeof(classNames[0]);

    for (int i = 0; i < numClasses; i++) {
        Class cls = objc_getClass(classNames[i]);
        if (cls) {
            snapLog("[SnapFix] Found Class: %s", classNames[i]);

            // 1. Hook للدوال التي ترجع BOOL (مثل isPremiumActive) -> نجعلها ترجع YES
            for (int j = 0; j < numCheckMethods; j++) {
                SEL sel = sel_registerName(checkMethods[j]);
                Method m = class_getInstanceMethod(cls, sel);
                if (m) {
                    const char *typeEncoding = method_getTypeEncoding(m);
                    if (typeEncoding[0] == 'B') { // إذا كانت ترجع BOOL
                        snapLog("[SnapFix] Hooked BOOL Method: %s.%s", classNames[i], checkMethods[j]);
                        method_setImplementation(m, (IMP)returnTrue);
                    }
                }
            }

            // 2. Hook للدوال التي تعرض الشاشة (مثل showSubscriptionSheet) -> نجعلها تفعل شيئاً أو تلغى
            for (int j = 0; j < numShowMethods; j++) {
                SEL sel = sel_registerName(showMethods[j]);
                Method m = class_getInstanceMethod(cls, sel);
                if (m) {
                    snapLog("[SnapFix] Hooked SHOW Method: %s.%s", classNames[i], showMethods[j]);
                    // نختار بين إلغاء الدالة تماماً أو استدعاء دالة فارغة
                    method_setImplementation(m, (IMP)doNothing);
                }
            }

            // 3. Hook للدوال التي تحتوي على كلمة "Validate" أو "Verify" مع Completion -> نجعلها تنجح
            // نبحث في جميع دوال الكلاس
            unsigned int methodCount;
            Method *methods = class_copyMethodList(cls, &methodCount);
            for (unsigned int k = 0; k < methodCount; k++) {
                Method m = methods[k];
                SEL sel = method_getName(m);
                const char *methodName = sel_getName(sel);
                
                // إذا كانت الدالة تبدأ بحروف مثل v (void) وتحتوي على كلمة Validate أو Verify
                const char *typeEncoding = method_getTypeEncoding(m);
                if (typeEncoding[0] == 'v') {
                    if ((strstr(methodName, "Validate") || strstr(methodName, "Verify") || strstr(methodName, "CheckCode")) && 
                        strstr(methodName, "Completion") || strstr(methodName, "Handler")) {
                        snapLog("[SnapFix] Hooked Callback Method: %s.%s", classNames[i], methodName);
                        method_setImplementation(m, (IMP)completeSuccess);
                    }
                }
            }
            free(methods);
        }
    }

    snapLog("[SnapFix] ===== FINISHED HOOKING =====");
}
