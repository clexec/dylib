// rxpatch_standalone.m — патч SecurityViewController в RXTikTok
// Устанавливает fake_verify=YES и автоматически пропускает экран ключа

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Bypass через UserDefaults — выставляем все возможные ключи сразу
static void setBypassKeys(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:YES forKey:@"fake_verify"];
    [ud setBool:YES forKey:@"en_fake"];
    [ud setBool:YES forKey:@"rx_verified"];
    [ud setBool:YES forKey:@"rx_activated"];
    [ud setBool:YES forKey:@"isVerified"];
    [ud setBool:YES forKey:@"verified"];
    // Disable app lock
    [ud setBool:NO  forKey:@"padlock"];
    [ud setBool:NO  forKey:@"appLock"];
    [ud setBool:NO  forKey:@"app_lock"];
    [ud setBool:NO  forKey:@"isPasscodeEnabled"];
    [ud synchronize];
}

// Swizzle SecurityViewController чтобы автоматически закрывался
@interface NSObject (RXPatch)
- (void)rxpatch_viewWillAppear:(BOOL)animated;
- (void)rxpatch_viewDidLoad;
@end

@implementation NSObject (RXPatch)
- (void)rxpatch_viewWillAppear:(BOOL)animated {
    // Сразу dismiss — не показываем экран ключа
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = (UIViewController *)self;
        if (vc.presentingViewController) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    });
}
- (void)rxpatch_viewDidLoad {
    [self rxpatch_viewDidLoad];
    // Автоматически dismiss
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = (UIViewController *)self;
        if (vc.presentingViewController) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    });
}
@end

static void installRXPatch(void) {
    // Выставляем ключи немедленно
    setBypassKeys();

    // Патчим SecurityViewController
    Class secVC = NSClassFromString(@"SecurityViewController");
    if (secVC) {
        Method wwa = class_getInstanceMethod(secVC, @selector(viewWillAppear:));
        Method rwwa = class_getInstanceMethod([NSObject class], @selector(rxpatch_viewWillAppear:));
        if (wwa && rwwa) method_exchangeImplementations(wwa, rwwa);

        Method vdl = class_getInstanceMethod(secVC, @selector(viewDidLoad));
        Method rvdl = class_getInstanceMethod([NSObject class], @selector(rxpatch_viewDidLoad));
        if (vdl && rvdl) method_exchangeImplementations(vdl, rvdl);
    }

    // Если есть метод authenticate — делаем его no-op
    Class rxMgr = NSClassFromString(@"RXIManager");
    if (rxMgr) {
        // Попробуем найти и патчить isPasscodeEnabled
        Method m = class_getInstanceMethod(rxMgr, @selector(isPasscodeEnabled));
        if (m) {
            method_setImplementation(m, imp_implementationWithBlock(^BOOL(id _){ return NO; }));
        }
        Method m2 = class_getInstanceMethod(rxMgr, @selector(appLock));
        if (m2) {
            method_setImplementation(m2, imp_implementationWithBlock(^BOOL(id _){ return NO; }));
        }
    }
}

__attribute__((constructor))
static void rxpatch_init(void) {
    // Немедленно
    setBypassKeys();

    // После загрузки всех классов RXTikTok
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        @try { installRXPatch(); } @catch(...) {}
    });

    // Повторно через 1 секунду на случай если первый раз был слишком рано
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        @try {
            setBypassKeys();
            // Ищем и dismiss любой SecurityViewController на экране
            UIWindow *win = nil;
            for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
                if ([sc isKindOfClass:[UIWindowScene class]])
                    for (UIWindow *w in ((UIWindowScene *)sc).windows)
                        if (!w.isHidden) { win = w; break; }
                if (win) break;
            }
            UIViewController *top = win.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            if ([NSStringFromClass([top class]) containsString:@"Security"] ||
                [NSStringFromClass([top class]) containsString:@"Lock"] ||
                [NSStringFromClass([top class]) containsString:@"Auth"]) {
                [top dismissViewControllerAnimated:NO completion:nil];
            }
        } @catch(...) {}
    });
}
