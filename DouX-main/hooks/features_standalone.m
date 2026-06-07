// features_standalone.m
// DeTok — Download, Feed, Profile, Security features
// Pure ObjC — no Ellekit needed
// All TikTok class hooks via method_exchangeImplementations

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ─── Settings ────────────────────────────────────────────────────────────────
#define FPREF(k) [[NSUserDefaults standardUserDefaults] boolForKey:(k)]

#define K_DOWNLOAD_BTN   @"dt_download_btn"
#define K_HIDE_ADS       @"dt_hide_ads"
#define K_PROGRESS_BAR   @"dt_progress_bar"
#define K_AUTO_PLAY      @"dt_auto_play"
#define K_STOP_LOOP      @"dt_stop_loop"
#define K_SKIP_RECS      @"dt_skip_recs"
#define K_SPEED_EN       @"dt_speed_enabled"
#define K_SPEED_VAL      @"dt_speed_value"
#define K_UPLOAD_REGION  @"dt_upload_region"
#define K_TRANSPARENT_C  @"dt_transparent_comments"
#define K_SHOW_USERNAME  @"dt_show_username"
#define K_NO_REFRESH     @"dt_no_pull_refresh"
#define K_NO_SENSITIVE   @"dt_no_sensitive"
#define K_NO_WARNINGS    @"dt_no_warnings"
#define K_NO_LIVE        @"dt_no_live"
#define K_PROFILE_SAVE   @"dt_profile_save"
#define K_PROFILE_COPY   @"dt_profile_copy"
#define K_VIDEO_LIKES    @"dt_video_likes"
#define K_VIDEO_DATE     @"dt_video_date"
#define K_VIDEO_COUNT    @"dt_video_count"
#define K_APP_LOCK       @"dt_app_lock"
#define K_LIKE_CONFIRM   @"dt_like_confirm"
#define K_FOLLOW_CONFIRM @"dt_follow_confirm"

// ─── Helpers ─────────────────────────────────────────────────────────────────
static void doux_swizzle(Class cls, SEL orig, SEL swiz) {
    Method o = class_getInstanceMethod(cls, orig);
    Method s = class_getInstanceMethod(cls, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

static UIViewController *doux_topVC(void) {
    UIWindow *win = nil;
    for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
        if ([sc isKindOfClass:[UIWindowScene class]])
            for (UIWindow *w in ((UIWindowScene *)sc).windows)
                if (!w.isHidden) { win = w; break; }
        if (win) break;
    }
    UIViewController *vc = win.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static void showConfirm(NSString *msg, void (^ok)(void)) {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"DeTok" message:msg
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) { ok(); }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"No"  style:UIAlertActionStyleCancel  handler:nil]];
    [doux_topVC() presentViewController:alert animated:YES completion:nil];
}

// ─── Download via tikwm.com (watermark-free) ─────────────────────────────────
static void downloadVideoWithID(NSString *videoID, BOOL hd) {
    if (!videoID.length) return;
    NSString *urlStr = hd
        ? [NSString stringWithFormat:@"https://tikwm.com/video/media/hdplay/%@.mp4", videoID]
        : [NSString stringWithFormat:@"https://tikwm.com/video/media/play/%@.mp4",   videoID];
    NSURL *url = [NSURL URLWithString:urlStr];

    UIAlertController *hud = [UIAlertController
        alertControllerWithTitle:@"Downloading..." message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [doux_topVC() presentViewController:hud animated:YES completion:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session downloadTaskWithURL:url completionHandler:^(NSURL *tmp, NSURLResponse *r, NSError *e) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud dismissViewControllerAnimated:NO completion:^{
                if (e || !tmp) {
                    UIAlertController *err = [UIAlertController
                        alertControllerWithTitle:@"Error" message:e.localizedDescription
                        preferredStyle:UIAlertControllerStyleAlert];
                    [err addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [doux_topVC() presentViewController:err animated:YES completion:nil];
                    return;
                }
                // Move to temp with .mp4 extension
                NSString *dest = [NSTemporaryDirectory() stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"%@.mp4", [[NSUUID UUID] UUIDString]]];
                [[NSFileManager defaultManager] moveItemAtURL:tmp
                    toURL:[NSURL fileURLWithPath:dest] error:nil];
                // Save to Photos
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:dest]];
                } completionHandler:^(BOOL success, NSError *err) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *msg = success ? @"Video saved to Photos!" : @"Save failed";
                        UIAlertController *done = [UIAlertController
                            alertControllerWithTitle:@"DeTok" message:msg
                            preferredStyle:UIAlertControllerStyleAlert];
                        [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                        [doux_topVC() presentViewController:done animated:YES completion:nil];
                    });
                }];
            }];
        });
    }] resume];
}

static void downloadAudioWithURL(NSString *audioURL) {
    if (!audioURL.length) return;
    NSURL *url = [NSURL URLWithString:audioURL];
    [[NSURLSession.sharedSession downloadTaskWithURL:url
        completionHandler:^(NSURL *tmp, NSURLResponse *r, NSError *e) {
        if (!tmp) return;
        NSString *dest = [NSTemporaryDirectory() stringByAppendingPathComponent:
            [[NSUUID UUID].UUIDString stringByAppendingString:@".mp3"]];
        [[NSFileManager defaultManager] moveItemAtURL:tmp
            toURL:[NSURL fileURLWithPath:dest] error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *fileURL = [NSURL fileURLWithPath:dest];
            UIActivityViewController *share = [[UIActivityViewController alloc]
                initWithActivityItems:@[fileURL] applicationActivities:nil];
            [doux_topVC() presentViewController:share animated:YES completion:nil];
        });
    }] resume];
}

// ─── Region flag emoji ────────────────────────────────────────────────────────
static NSString *flagEmojiForCode(NSString *code) {
    if (code.length != 2) return @"";
    uint32_t a = [code.uppercaseString characterAtIndex:0] + 0x1F1E6 - 'A';
    uint32_t b = [code.uppercaseString characterAtIndex:1] + 0x1F1E6 - 'A';
    NSString *flag = [[NSString alloc] initWithBytes:&a length:4 encoding:NSUTF32LittleEndianStringEncoding];
    return [flag stringByAppendingString:
        [[NSString alloc] initWithBytes:&b length:4 encoding:NSUTF32LittleEndianStringEncoding]];
}

// ─── App Lock ─────────────────────────────────────────────────────────────────
static BOOL _lockShown = NO;

static void showAppLockIfNeeded(void) {
    if (!FPREF(K_APP_LOCK) || _lockShown) return;
    _lockShown = YES;
    LAContext *ctx = [LAContext new];
    NSError *err;
    if ([ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&err]) {
        [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:@"Unlock DeTok"
                      reply:^(BOOL success, NSError *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) showAppLockIfNeeded(); // retry on fail
            });
        }];
    }
}

// ─── Settings VC ─────────────────────────────────────────────────────────────
typedef struct { const char *key; const char *title; } FSetting;

static FSetting kFeedSettings[] = {
    { "dt_hide_ads",           "Hide Ads"                       },
    { "dt_progress_bar",       "Progress Bar (Seekable)"        },
    { "dt_auto_play",          "Auto-advance to Next Video"     },
    { "dt_stop_loop",          "Don't Loop Videos"              },
    { "dt_skip_recs",          "Skip Recommended Posts"         },
    { "dt_transparent_comments","Transparent Comments"          },
    { "dt_show_username",      "Show @Username in Feed"         },
    { "dt_no_pull_refresh",    "Disable Pull-to-Refresh"        },
    { "dt_no_sensitive",       "Disable Sensitive Blur"         },
    { "dt_no_warnings",        "Remove Content Warnings"        },
    { "dt_no_live",            "Hide LIVE in Feed"              },
    { "dt_upload_region",      "Show Upload Country Flag"       },
    { "dt_download_btn",       "Download Button on Videos"      },
};
static const int kFeedCount = 13;

static FSetting kProfileSettings[] = {
    { "dt_profile_save",  "Save Profile Photo (Long Press)" },
    { "dt_profile_copy",  "Copy Profile Bio (Long Press)"   },
    { "dt_video_likes",   "Show Likes on Profile Grid"      },
    { "dt_video_date",    "Show Upload Date on Grid"        },
    { "dt_video_count",   "Show Video Count on Profile"     },
};
static const int kProfileCount = 5;

static FSetting kSecuritySettings[] = {
    { "dt_app_lock",       "App Lock (Face ID / Touch ID)"      },
    { "dt_like_confirm",   "Confirm Before Liking"              },
    { "dt_follow_confirm", "Confirm Before Following"           },
};
static const int kSecurityCount = 3;

@interface FeaturesSettingsVC : UITableViewController
@end

@implementation FeaturesSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Features";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self action:@selector(close)];

    // Speed section header note
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,60)];
    footer.text = @"Speed: set in Feed section — 0.5x 0.75x 1x 1.5x 2x 3x";
    footer.font = [UIFont systemFontOfSize:12];
    footer.textColor = [UIColor secondaryLabelColor];
    footer.numberOfLines = 0;
    footer.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableFooterView = footer;
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 4; }

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    switch (s) {
        case 0: return @"Feed & UI";
        case 1: return @"Playback Speed";
        case 2: return @"Profile";
        case 3: return @"Security";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    switch (s) {
        case 0: return kFeedCount;
        case 1: return 6; // speeds
        case 2: return kProfileCount;
        case 3: return kSecurityCount;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (ip.section == 1) {
        // Speed picker
        CGFloat speeds[] = {0.5f, 0.75f, 1.0f, 1.5f, 2.0f, 3.0f};
        NSString *labels[] = {@"0.5×", @"0.75×", @"1× (Normal)", @"1.5×", @"2×", @"3×"};
        cell.textLabel.text = labels[ip.row];
        CGFloat saved = [[NSUserDefaults standardUserDefaults] floatForKey:K_SPEED_VAL];
        if (saved == 0) saved = 1.0f;
        cell.accessoryType = (fabsf(saved - speeds[ip.row]) < 0.01f)
            ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        return cell;
    }

    const char *key, *title;
    if (ip.section == 0) { key = kFeedSettings[ip.row].key;      title = kFeedSettings[ip.row].title; }
    else if (ip.section == 2) { key = kProfileSettings[ip.row].key; title = kProfileSettings[ip.row].title; }
    else { key = kSecuritySettings[ip.row].key; title = kSecuritySettings[ip.row].title; }

    cell.textLabel.text = @(title);
    UISwitch *sw = [UISwitch new];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:@(key)];
    sw.tag = ip.section * 100 + ip.row;
    [sw addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section != 1) return;
    CGFloat speeds[] = {0.5f, 0.75f, 1.0f, 1.5f, 2.0f, 3.0f};
    [[NSUserDefaults standardUserDefaults] setFloat:speeds[ip.row] forKey:K_SPEED_VAL];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:K_SPEED_EN];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [tv reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)toggled:(UISwitch *)sw {
    int section = (int)(sw.tag / 100);
    int row     = (int)(sw.tag % 100);
    const char *key;
    if (section == 0)      key = kFeedSettings[row].key;
    else if (section == 2) key = kProfileSettings[row].key;
    else                   key = kSecuritySettings[row].key;
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@(key)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

UIViewController *doux_featuresSettingsVC(void) {
    return [FeaturesSettingsVC new];
}

// ─── ObjC hooks via swizzling ─────────────────────────────────────────────────

// AWEAwemeModel — hide ads + progress bar
@interface NSObject (DeTokAweme)
- (BOOL)dt_isAds;
- (BOOL)dt_progressBarDraggable;
- (BOOL)dt_progressBarVisible;
- (void)dt_live_callInitWithDictyCategoryMethod:(id)arg1;
@end

@implementation NSObject (DeTokAweme)
- (BOOL)dt_isAds {
    if (FPREF(K_HIDE_ADS)) return NO;
    return ((BOOL(*)(id,SEL))objc_msgSend)(self, @selector(dt_isAds));
}
- (BOOL)dt_progressBarDraggable {
    if (FPREF(K_PROGRESS_BAR)) return YES;
    return ((BOOL(*)(id,SEL))objc_msgSend)(self, @selector(dt_progressBarDraggable));
}
- (BOOL)dt_progressBarVisible {
    if (FPREF(K_PROGRESS_BAR)) return YES;
    return ((BOOL(*)(id,SEL))objc_msgSend)(self, @selector(dt_progressBarVisible));
}
- (void)dt_live_callInitWithDictyCategoryMethod:(id)arg1 {
    if (!FPREF(K_NO_LIVE))
        ((void(*)(id,SEL,id))objc_msgSend)(self, @selector(dt_live_callInitWithDictyCategoryMethod:), arg1);
}
@end

// TTKMediaSpeedControlService — playback speed
@interface NSObject (DeTokSpeed)
- (void)dt_setPlaybackRate:(CGFloat)rate;
@end

@implementation NSObject (DeTokSpeed)
- (void)dt_setPlaybackRate:(CGFloat)rate {
    CGFloat speed = [[NSUserDefaults standardUserDefaults] floatForKey:K_SPEED_VAL];
    if (FPREF(K_SPEED_EN) && speed > 0)
        ((void(*)(id,SEL,CGFloat))objc_msgSend)(self, @selector(dt_setPlaybackRate:), speed);
    else
        ((void(*)(id,SEL,CGFloat))objc_msgSend)(self, @selector(dt_setPlaybackRate:), rate);
}
@end

// AWEMaskInfoModel — no sensitive blur
@interface NSObject (DeTokMask)
- (BOOL)dt_showMask;
- (void)dt_setShowMask:(BOOL)v;
@end

@implementation NSObject (DeTokMask)
- (BOOL)dt_showMask {
    if (FPREF(K_NO_SENSITIVE)) return NO;
    return ((BOOL(*)(id,SEL))objc_msgSend)(self, @selector(dt_showMask));
}
- (void)dt_setShowMask:(BOOL)v {
    ((void(*)(id,SEL,BOOL))objc_msgSend)(self, @selector(dt_setShowMask:), FPREF(K_NO_SENSITIVE) ? NO : v);
}
@end

// AWEProfileEditTextViewController — extended bio
@interface NSObject (DeTokBio)
- (NSInteger)dt_maxTextLength;
@end

@implementation NSObject (DeTokBio)
- (NSInteger)dt_maxTextLength {
    NSInteger orig = ((NSInteger(*)(id,SEL))objc_msgSend)(self, @selector(dt_maxTextLength));
    return 300; // extended always — original is ~80
}
@end

// AWETextInputController — extended comment
@interface NSObject (DeTokComment)
- (NSUInteger)dt_maxLength;
@end

@implementation NSObject (DeTokComment)
- (NSUInteger)dt_maxLength {
    return 500;
}
@end

// ─── App Lock via UIApplicationDelegate swizzle ───────────────────────────────
@interface UIResponder (DeTokLock)
- (void)dt_applicationDidBecomeActive:(UIApplication *)app;
@end

@implementation UIResponder (DeTokLock)
- (void)dt_applicationDidBecomeActive:(UIApplication *)app {
    ((void(*)(id,SEL,id))objc_msgSend)(self, @selector(dt_applicationDidBecomeActive:), app);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ showAppLockIfNeeded(); });
}
@end

// ─── Install all hooks ────────────────────────────────────────────────────────
static void installFeatureHooks(void) {
    // AWEAwemeModel hooks
    Class aweme = NSClassFromString(@"AWEAwemeModel");
    if (aweme) {
        doux_swizzle(aweme, @selector(isAds),                              @selector(dt_isAds));
        doux_swizzle(aweme, @selector(progressBarDraggable),               @selector(dt_progressBarDraggable));
        doux_swizzle(aweme, @selector(progressBarVisible),                 @selector(dt_progressBarVisible));
        doux_swizzle(aweme, @selector(live_callInitWithDictyCategoryMethod:), @selector(dt_live_callInitWithDictyCategoryMethod:));
    }

    // Speed
    Class speed = NSClassFromString(@"TTKMediaSpeedControlService");
    if (speed) doux_swizzle(speed, @selector(setPlaybackRate:), @selector(dt_setPlaybackRate:));

    // Sensitive content
    Class mask = NSClassFromString(@"AWEMaskInfoModel");
    if (mask) {
        doux_swizzle(mask, @selector(showMask),          @selector(dt_showMask));
        doux_swizzle(mask, @selector(setShowMask:),      @selector(dt_setShowMask:));
    }

    // Extended bio
    Class bioVC = NSClassFromString(@"AWEProfileEditTextViewController");
    if (bioVC) doux_swizzle(bioVC, @selector(maxTextLength), @selector(dt_maxTextLength));

    // Extended comment
    Class textInput = NSClassFromString(@"AWETextInputController");
    if (textInput) doux_swizzle(textInput, @selector(maxLength), @selector(dt_maxLength));

    // App lock — hook AppDelegate
    Class appDelegate = NSClassFromString(@"AppDelegate");
    if (!appDelegate) appDelegate = NSClassFromString(@"TikTokAppDelegate");
    if (appDelegate) {
        doux_swizzle(appDelegate,
            @selector(applicationDidBecomeActive:),
            @selector(dt_applicationDidBecomeActive:));
    }
}

// ─── Entry point ──────────────────────────────────────────────────────────────
__attribute__((constructor))
static void features_init(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        installFeatureHooks();
    });
}
