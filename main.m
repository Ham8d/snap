#include <substrate.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <stdio.h>
#include <stdlib.h>
#include <dispatch/dispatch.h>

void snapLog(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
}

// دالة ترجع نجاح دائماً
static BOOL returnTrue(id self, SEL _cmd) {
    snapLog("[SnapFix] Return True: %s", sel_getName(_cmd));
    return YES;
}

// دالة تلغي التنفيذ
static void doNothing(id self, SEL _cmd) {
    snapLog("[SnapFix] Do Nothing: %s", sel_getName(_cmd));
}

// دالة تجبر النجاح في الـ Callbacks
static void forceSuccessCallback(id self, SEL _cmd, void *completion) {
    snapLog("[SnapFix] Force Success Callback: %s", sel_getName(_cmd));
    if (completion) {
        void (*callBack)(void*, BOOL) = (void (*)(void*, BOOL))completion;
        callBack(completion, YES);
    }
}

__attribute__((constructor))
void initialize() {
    snapLog("[SnapFix] ===== FINAL FIX STARTED =====");

    // أسماء الكلاسات الشائعة
    const char *classNames[] = {
        "SUBSubscriptionManager", "SCSubscriptionManager",
        "SUBAppController", "SCAppController",
        "AppDelegate", "RootViewController",
        "LoginViewController", "SplashViewController",
        "NetworkManager", "ApiManager"
    };
    int numClasses = sizeof(classNames) / sizeof(classNames[0]);

    // أسماء الدوال التي نريد تعطيلها أو تعديلها
    const char *checkMethods[] = {
        "isPremiumActive", "isSubscribed", "isValid", "hasActiveSubscription",
        "isPremium", "checkSubscriptionStatus", "validateSubscription",
        "isLoggedIn", "isUserLoggedIn", "checkLoginStatus",
        "verifyCode", "isValidCode", "checkNetworkStatus", "isConnected"
    };
    int numCheckMethods = sizeof(checkMethods) / sizeof(checkMethods[0]);

    const char *showMethods[] = {
        "showSubscriptionSheet", "presentSubscriptionView", "showPremiumAlert",
        "displaySubscriptionModal", "showPaywall", "presentPaywall",
        "showLoginAlert", "showErrorAlert", "showNetworkError",
        "presentLoginViewController", "showSplashScreen"
    };
    int numShowMethods = sizeof(showMethods) / sizeof(showMethods[0]);

    for (int i = 0; i < numClasses; i++) {
        Class cls = objc_getClass(classNames[i]);
        if (cls) {
            snapLog("[SnapFix] Found Class: %s", classNames[i]);

            // 1. جعل دوال التحقق ترجع YES
            for (int j = 0; j < numCheckMethods; j++) {
                SEL sel = sel_registerName(checkMethods[j]);
                Method m = class_getInstanceMethod(cls, sel);
                if (m) {
                    const char *typeEncoding = method_getTypeEncoding(m);
                    if (typeEncoding[0] == 'B') { // يرجع BOOL
                        snapLog("[SnapFix] Hooked BOOL: %s.%s", classNames[i], checkMethods[j]);
                        method_setImplementation(m, (IMP)returnTrue);
                    }
                }
            }

            // 2. تعطيل دوال العرض والتنبيهات
            for (int j = 0; j < numShowMethods; j++) {
                SEL sel = sel_registerName(showMethods[j]);
                Method m = class_getInstanceMethod(cls, sel);
                if (m) {
                    snapLog("[SnapFix] Hooked SHOW: %s.%s", classNames[i], showMethods[j]);
                    method_setImplementation(m, (IMP)doNothing);
                }
            }

            // 3. البحث عن أي دالة تحتوي على "Login" أو "Network" أو "Check" وتنتهي بـ "Completion" أو "Handler"
            unsigned int methodCount;
            Method *methods = class_copyMethodList(cls, &methodCount);
            for (unsigned int k = 0; k < methodCount; k++) {
                Method m = methods[k];
                SEL sel = method_getName(m);
                const char *methodName = sel_getName(sel);
                const char *typeEncoding = method_getTypeEncoding(m);

                // إذا كانت الدالة فارغة الإرجاع (void) وتحتوي على كلمات مفتاحية
                if (typeEncoding[0] == 'v') {
                    if ((strstr(methodName, "Login") || strstr(methodName, "Network") || 
                         strstr(methodName, "Check") || strstr(methodName, "Verify")) &&
                        (strstr(methodName, "Completion") || strstr(methodName, "Handler") || strstr(methodName, "Callback"))) {
                        snapLog("[SnapFix] Hooked Callback: %s.%s", classNames[i], methodName);
                        method_setImplementation(m, (IMP)forceSuccessCallback);
                    }
                }
            }
            free(methods);
        }
    }

    snapLog("[SnapFix] ===== FINAL FIX ENDED =====");
}
