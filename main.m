#import "substrate.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// تعريف كلاس افتراضي لسناب (قد يختلف حسب النسخة)
@interface SUBSubscriptionManager : NSObject
- (BOOL)isPremiumActive;
- (void)requestSubscriptionCodeWithCompletion:(void(^)(BOOL success, NSString *error))completion;
- (void)validateCode:(NSString *)code completion:(void(^)(BOOL valid))completion;
@end

@interface SUBAppController : NSObject
- (BOOL)isSubscribed;
@end

// Hook للدالة التي تحقق من الاشتراك
%hook SUBSubscriptionManager

- (BOOL)isPremiumActive {
    NSLog(@"[SnapFix] isPremiumActive called. Returning YES.");
    return YES;
}

- (void)requestSubscriptionCodeWithCompletion:(void(^)(BOOL success, NSString *error))completion {
    NSLog(@"[SnapFix] requestSubscriptionCode intercepted.");
    if (completion) {
        completion(YES, nil);
    }
}

- (void)validateCode:(NSString *)code completion:(void(^)(BOOL valid))completion {
    NSLog(@"[SnapFix] validateCode intercepted for code: %@", code);
    if (completion) {
        completion(YES);
    }
}

%end

// Hook للكلاس الرئيسي إذا كان يستخدمه سناب
%hook SUBAppController

- (BOOL)isSubscribed {
    NSLog(@"[SnapFix] SUBAppController isSubscribed called. Returning YES.");
    return YES;
}

%end

// دالة التهيئة
__attribute__((constructor))
void initialize() {
    NSLog(@"[SnapFix] CydiaSubstrate Library Loaded Successfully!");
    
    // اختياري: تأخير التحميل قليلاً لتجنب الكراش في بداية التطبيق
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC), dispatch_get_main_queue()), ^{
        NSLog(@"[SnapFix] Delayed initialization complete.");
    });
}
