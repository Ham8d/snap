#include <substrate.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <stdarg.h>

// تعريفات أساسية لتجنب اعتماد كامل على Foundation.h
typedef struct objc_object {
    Class isa;
} *id;

typedef struct objc_selector {
    const char *name;
} *SEL;

typedef struct objc_class {
    struct objc_class *isa;
    struct objc_class *super_class;
    void *cache;
    void *vtable;
} *Class;

// تعريف دالة NSLog مخصصة لتجنب مشكلة "file not found" لـ Foundation
void myNSLog(const char *format, ...) {
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
    printf("\n");
}

// دوال الـ Hook

static BOOL isPremiumOverride(id self, SEL _cmd) {
    myNSLog("[SnapFix] isPremiumActive -> YES");
    return YES;
}

// ملاحظة: نوع الـ callback قد يختلف، نستخدم مؤشر دالة عام لتجنب تعقيدات النوع
static void requestSubscriptionOverride(id self, SEL _cmd, void *completion) {
    myNSLog("[SnapFix] requestSubscriptionCodeWithCompletion -> Success");
    if (completion) {
        // استدعاء الكومبليشن بنجاح
        // النوع الدقيق يعتمد على تعريف الدالة الأصلية في سناب
        // هنا نفترض أن الأول BOOL والثاني NSString (id)
        void (*callCompletion)(void*, BOOL, id) = (void (*)(void*, BOOL, id))completion;
        callCompletion(completion, YES, nil);
    }
}

static void validateCodeOverride(id self, SEL _cmd, id code, void *completion) {
    myNSLog("[SnapFix] validateCode -> Valid");
    if (completion) {
        void (*callCompletion)(void*, BOOL) = (void (*)(void*, BOOL))completion;
        callCompletion(completion, YES);
    }
}

static BOOL isSubscribedOverride(id self, SEL _cmd) {
    myNSLog("[SnapFix] isSubscribed -> YES");
    return YES;
}

__attribute__((constructor))
void initialize() {
    myNSLog("[SnapFix] Library Loaded!");

    // محاولة Hook للكلاسات الشائعة في سناب
    Class subMgrClass = objc_getClass("SUBSubscriptionManager");
    if (subMgrClass) {
        Method m = class_getInstanceMethod(subMgrClass, @selector(isPremiumActive));
        if (m) method_setImplementation(m, (IMP)isPremiumOverride);
        
        m = class_getInstanceMethod(subMgrClass, @selector(requestSubscriptionCodeWithCompletion:));
        if (m) method_setImplementation(m, (IMP)requestSubscriptionOverride);

        m = class_getInstanceMethod(subMgrClass, @selector(validateCode:completion:));
        if (m) method_setImplementation(m, (IMP)validateCodeOverride);
    }

    Class appCtrlClass = objc_getClass("SUBAppController");
    if (appCtrlClass) {
        Method m = class_getInstanceMethod(appCtrlClass, @selector(isSubscribed));
        if (m) method_setImplementation(m, (IMP)isSubscribedOverride);
    }
}
