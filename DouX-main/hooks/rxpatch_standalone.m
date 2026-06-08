// rxpatch_standalone.m — RXTikTok lock/key bypass
// Точечные хуки под реальные классы RXTikTok 1.6.6:
//   RXIManager           — менеджер настроек (passcode / appLock / getBoolForKey:)
//   SecurityViewController — экран блокировки (пароль/ключ)
// RXPatch.dylib грузится ПОСЛЕ ___RXTikTok, поэтому все классы уже
// зарегистрированы в рантайме к моменту конструктора — хуки встают сразу.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static void setBypassDefaults(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray<NSString *> *on = @[ @"fake_verify", @"en_fake", @"fakeVerified",
        @"isVerified", @"verified", @"rx_verified", @"rx_activated" ];
    NSArray<NSString *> *off = @[ @"padlock", @"appLock", @"app_lock",
        @"isPasscodeEnabled", @"isAppLockEnabled", @"securityEnabled" ];
    for (NSString *k in on)  [ud setBool:YES forKey:k];
    for (NSString *k in off) [ud setBool:NO  forKey:k];
    [ud synchronize];
}

// Заменяет/добавляет boolean-геттер на классе, заставляя его вернуть фикс. значение.
static void forceBool(Class c, SEL sel, BOOL val) {
    if (!c || !sel) return;
    IMP imp = imp_implementationWithBlock(^BOOL(__unused id s){ return val; });
    Method m = class_getInstanceMethod(c, sel);
    if (m) method_setImplementation(m, imp);
    else   class_addMethod(c, sel, imp, "c@:");
}

static BOOL keyIsLock(NSString *k) {
    k = k.lowercaseString;
    return [k containsString:@"passcode"] || [k containsString:@"applock"] ||
           [k containsString:@"app_lock"] || [k containsString:@"padlock"]  ||
           [k containsString:@"security"] || [k isEqualToString:@"lock"];
}
static BOOL keyIsVerify(NSString *k) {
    k = k.lowercaseString;
    return [k containsString:@"verif"] || [k containsString:@"fake"] ||
           [k containsString:@"activ"];
}

// Оборачивает getBoolForKey:/boolForKey: — глушит lock-ключи, включает verify-ключи,
// остальное отдаёт оригиналу (в т.ч. значения из Keychain).
static void hookGetBool(Class c, SEL sel) {
    if (!c || !sel) return;
    Method m = class_getInstanceMethod(c, sel);
    if (!m) return;
    IMP orig = method_getImplementation(m);
    IMP imp = imp_implementationWithBlock(^BOOL(id s, NSString *key){
        if ([key isKindOfClass:NSString.class]) {
            if (keyIsLock(key))   return NO;
            if (keyIsVerify(key)) return YES;
        }
        return ((BOOL (*)(id, SEL, NSString *))orig)(s, sel, key);
    });
    method_setImplementation(m, imp);
}

static void dismissLockOnScreen(void) {
    UIWindow *win = nil;
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if ([sc isKindOfClass:UIWindowScene.class]) {
            for (UIWindow *w in ((UIWindowScene *)sc).windows) {
                if (w.isKeyWindow) { win = w; break; }
                if (!w.isHidden) win = w;
            }
        }
        if (win) break;
    }
    UIViewController *top = win.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    if (!top) return;
    NSString *cls = NSStringFromClass(top.class);
    if ([cls containsString:@"Security"] || [cls containsString:@"Lock"]     ||
        [cls containsString:@"Passcode"] || [cls containsString:@"Auth"]) {
        [top dismissViewControllerAnimated:NO completion:nil];
    }
}

static void installHooks(void) {
    setBypassDefaults();

    Class rx = NSClassFromString(@"RXIManager");
    forceBool(rx, @selector(isPasscodeEnabled), NO);
    forceBool(rx, NSSelectorFromString(@"appLock"), NO);
    forceBool(rx, NSSelectorFromString(@"isAppLockEnabled"), NO);
    forceBool(rx, NSSelectorFromString(@"fakeVerified"), YES);
    forceBool(rx, NSSelectorFromString(@"isVerified"), YES);
    hookGetBool(rx, @selector(getBoolForKey:));
    hookGetBool(rx, NSSelectorFromString(@"boolForKey:"));

    Class sec = NSClassFromString(@"SecurityViewController");
    if (sec) {
        forceBool(sec, @selector(isPasscodeEnabled), NO);
        SEL vda = @selector(viewDidAppear:);
        IMP imp = imp_implementationWithBlock(^(UIViewController *s, __unused BOOL a){
            if (s.presentingViewController)
                [s dismissViewControllerAnimated:NO completion:nil];
            else
                s.view.hidden = YES;
        });
        Method m = class_getInstanceMethod(sec, vda);
        if (m) method_setImplementation(m, imp);
        else   class_addMethod(sec, vda, imp, "v@:c");
    }
}

__attribute__((constructor))
static void rxpatch_init(void) {
    setBypassDefaults();
    @try { installHooks(); } @catch (__unused NSException *e) {}

    dispatch_async(dispatch_get_main_queue(), ^{
        @try { installHooks(); dismissLockOnScreen(); } @catch (__unused NSException *e) {}
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        @try { installHooks(); dismissLockOnScreen(); } @catch (__unused NSException *e) {}
    });
}
