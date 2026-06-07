// ghost_standalone.m
// DeTok Ghost Mode — Pure ObjC, zero Ellekit dependency
// Intercepts via NSURLProtocol + ObjC swizzling
// Settings: 3-finger triple-tap anywhere in TikTok

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ─── Settings keys ────────────────────────────────────────────────────────────
#define K_READ          @"doux_ghost_read"
#define K_PROFILE       @"doux_ghost_profile"
#define K_ONLINE        @"doux_ghost_online"
#define K_TYPING        @"doux_ghost_typing"
#define K_DELIVERED     @"doux_ghost_delivered"
#define K_SCREENSHOT    @"doux_ghost_screenshot"
#define K_STORY         @"doux_ghost_story"
#define K_LIVE          @"doux_ghost_live"
#define K_ANALYTICS     @"doux_ghost_analytics"
#define K_SHARE         @"doux_ghost_share"
#define K_SEARCH        @"doux_ghost_search"
#define K_LINK          @"doux_ghost_link"
#define K_SEEN_TS       @"doux_ghost_seen_ts"
#define K_NOTIFY_ACT    @"doux_ghost_notify_act"
#define K_LAST_SEEN     @"doux_ghost_last_seen"
#define K_LAST_SEEN_VAL @"doux_ghost_last_seen_val"

#define PREF(k) [[NSUserDefaults standardUserDefaults] boolForKey:(k)]

// ─── Auth URL whitelist — NEVER block ─────────────────────────────────────────
static BOOL isAuthURL(NSString *url) {
    return [url containsString:@"passport"]     ||
           [url containsString:@"/login"]       ||
           [url containsString:@"/register"]    ||
           [url containsString:@"account/info"] ||
           [url containsString:@"captcha"]      ||
           [url containsString:@"/verify"]      ||
           [url containsString:@"send_code"]    ||
           [url containsString:@"oauth"]        ||
           [url containsString:@"access_token"] ||
           [url containsString:@"refresh_token"]||
           [url containsString:@"sso"]          ||
           [url containsString:@"webview"];
}

// ─── URL block rules ──────────────────────────────────────────────────────────
static BOOL ghostShouldBlock(NSString *url) {
    if (!url.length) return NO;
    if (isAuthURL(url)) return NO;

    // Read receipts
    if (PREF(K_READ) && (
        [url containsString:@"mark_read"]     ||
        [url containsString:@"markRead"]      ||
        [url containsString:@"/im/ack"]       ||
        [url containsString:@"clear_unread"]  ||
        [url containsString:@"bulletin/clear"]||
        [url containsString:@"read_receipt"]
    )) return YES;

    // Profile views
    if (PREF(K_PROFILE) && (
        [url containsString:@"profile/view_record"] ||
        [url containsString:@"profile_view"]         ||
        [url containsString:@"profileviewscontrol"]  ||
        [url containsString:@"visit_record"]
    )) return YES;

    // Online status
    if (PREF(K_ONLINE) && (
        [url containsString:@"im/presence"]   ||
        [url containsString:@"online_status"] ||
        [url containsString:@"im/status"]     ||
        [url containsString:@"user_status"]   ||
        [url containsString:@"heartbeat"]
    )) return YES;

    // Typing indicator
    if (PREF(K_TYPING) && (
        [url containsString:@"im/typing"]           ||
        [url containsString:@"typing_recommendation"]||
        [url containsString:@"typing_status"]
    )) return YES;

    // Delivery receipts
    if (PREF(K_DELIVERED) && (
        [url containsString:@"msg/deliver"]     ||
        [url containsString:@"message/deliver"] ||
        [url containsString:@"im/deliver"]      ||
        [url containsString:@"delivery_receipt"]
    )) return YES;

    // Screenshot detection
    if (PREF(K_SCREENSHOT) && (
        [url containsString:@"screenshot"]  ||
        [url containsString:@"screen_shot"] ||
        [url containsString:@"capture_event"]
    )) return YES;

    // Story/slideshow views
    if (PREF(K_STORY) && (
        [url containsString:@"story/view"]       ||
        [url containsString:@"story_view"]       ||
        [url containsString:@"slideshow/view"]   ||
        [url containsString:@"carousel/viewed"]  ||
        [url containsString:@"photo_album/view"]
    )) return YES;

    // LIVE viewer registration
    if (PREF(K_LIVE) && (
        [url containsString:@"live/enter"]        ||
        [url containsString:@"live/viewer"]       ||
        [url containsString:@"live_room/enter"]   ||
        [url containsString:@"room/viewer/enter"] ||
        [url containsString:@"live/report_viewer"]
    )) return YES;

    // Analytics / watch time
    if (PREF(K_ANALYTICS) && (
        [url containsString:@"/log/"]          ||
        [url containsString:@"applog"]         ||
        [url containsString:@"monitor_collect"]||
        [url containsString:@"watch_time"]     ||
        [url containsString:@"video_complete"] ||
        [url containsString:@"play_progress"]  ||
        [url containsString:@"behavior_log"]   ||
        [url containsString:@"user_event"]     ||
        [url containsString:@"report/aweme"]
    )) return YES;

    // Share tracking
    if (PREF(K_SHARE) && (
        [url containsString:@"share/track"]   ||
        [url containsString:@"share/report"]  ||
        [url containsString:@"share_event"]   ||
        [url containsString:@"forward/report"]
    )) return YES;

    // Search tracking
    if (PREF(K_SEARCH) && (
        [url containsString:@"search/log"]    ||
        [url containsString:@"search_report"] ||
        [url containsString:@"suggest/track"]
    )) return YES;

    // Link click tracking
    if (PREF(K_LINK) && (
        [url containsString:@"link_click"]    ||
        [url containsString:@"click_track"]   ||
        [url containsString:@"outlink/report"]||
        [url containsString:@"bio_link/track"]
    )) return YES;

    // Activity notifications (like/follow visible to others)
    if (PREF(K_NOTIFY_ACT) && (
        [url containsString:@"notify/like"]      ||
        [url containsString:@"notify/follow"]    ||
        [url containsString:@"activity/report"]  ||
        [url containsString:@"feed/action/report"]
    )) return YES;

    return NO;
}

// ─── NSURLProtocol interceptor ────────────────────────────────────────────────
@interface GhostProtocol : NSURLProtocol
@end

@implementation GhostProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)req {
    if ([NSURLProtocol propertyForKey:@"GhostDone" inRequest:req]) return NO;
    return ghostShouldBlock(req.URL.absoluteString);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)req { return req; }

- (void)startLoading {
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc]
        initWithURL:self.request.URL
         statusCode:200
        HTTPVersion:@"HTTP/1.1"
       headerFields:@{@"Content-Type": @"application/json"}];
    NSData *body = [@"{\"status_code\":0,\"status_msg\":\"ok\"}"
        dataUsingEncoding:NSUTF8StringEncoding];
    [self.client URLProtocol:self didReceiveResponse:resp
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:body];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {}
@end

// ─── ObjC swizzle helpers ─────────────────────────────────────────────────────
static void swizzle_instance(Class cls, SEL orig, SEL swiz) {
    Method o = class_getInstanceMethod(cls, orig);
    Method s = class_getInstanceMethod(cls, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

static void swizzle_class(Class cls, SEL orig, SEL swiz) {
    Method o = class_getClassMethod(cls, orig);
    Method s = class_getClassMethod(cls, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

// ─── Screenshot detection block ───────────────────────────────────────────────
// Swizzle UIApplication to suppress TikTok's screenshot notification hooks
@interface UIApplication (GhostScreenshot)
- (void)doux_sendEvent:(UIEvent *)event;
@end

@implementation UIApplication (GhostScreenshot)
- (void)doux_sendEvent:(UIEvent *)event {
    // Block screenshot-type events from reaching TikTok's handlers when ghost is on
    if (PREF(K_SCREENSHOT)) {
        NSString *desc = event.description;
        if ([desc containsString:@"Screenshot"] || [desc containsString:@"screenshot"]) {
            return; // drop the event
        }
    }
    [self doux_sendEvent:event];
}
@end

// ─── "Seen at X:XX" timestamp hide ───────────────────────────────────────────
// Swizzle UILabel setText to suppress TikTok's read-time labels
@interface UILabel (GhostSeenTS)
- (void)doux_setText:(NSString *)text;
@end

@implementation UILabel (GhostSeenTS)
- (void)doux_setText:(NSString *)text {
    if (PREF(K_SEEN_TS) && text.length > 0) {
        // Hide "Seen", "Read", "Просмотрено" timestamps in chat
        NSString *lower = [text lowercaseString];
        if ([lower containsString:@"seen at"]     ||
            [lower containsString:@"read at"]     ||
            [lower containsString:@"viewed at"]   ||
            [lower containsString:@"просмотрено"] ||
            [lower containsString:@"прочитано"]) {
            [self doux_setText:@""];
            self.hidden = YES;
            return;
        }
    }
    [self doux_setText:text];
}
@end

// ─── Settings UI ──────────────────────────────────────────────────────────────
typedef struct {
    const char *key;
    const char *title;
    const char *detail;
} GhostSetting;

static GhostSetting kSettings[] = {
    { "doux_ghost_read",       "Hide Read Receipts",          "Don't send 'Seen' to sender"              },
    { "doux_ghost_seen_ts",    "Hide 'Seen at X:XX'",         "Remove timestamp in your DMs"             },
    { "doux_ghost_delivered",  "Block 'Delivered' Status",    "Message won't show as delivered"          },
    { "doux_ghost_profile",    "Hide Profile Views",          "Won't appear in viewers list"             },
    { "doux_ghost_online",     "Appear Offline",              "Always show as offline"                   },
    { "doux_ghost_typing",     "Hide Typing Indicator",       "Don't send typing events"                 },
    { "doux_ghost_screenshot", "Anti-Screenshot Detection",   "TikTok won't know you screenshotted"      },
    { "doux_ghost_story",      "Hide Story/Slide Views",      "Won't register carousel/photo views"      },
    { "doux_ghost_live",       "Anonymous LIVE Viewing",      "Won't appear in LIVE viewer list"         },
    { "doux_ghost_analytics",  "Block Watch Analytics",       "TikTok won't track your watch time"       },
    { "doux_ghost_share",      "Hide Share Tracking",         "Sender won't know you forwarded"          },
    { "doux_ghost_search",     "Block Search Tracking",       "Your searches won't be saved server-side" },
    { "doux_ghost_link",       "Block Link Click Tracking",   "Opening links won't be reported"          },
    { "doux_ghost_notify_act", "Hide Activity Notifications", "Your likes/follows hidden from others"    },
    { "doux_ghost_last_seen",  "Fake Last Seen",              "Custom 'last active' time shown"          },
};
static const int kSettingsCount = 15;

@interface GhostSettingsVC : UITableViewController
@end

@implementation GhostSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Ghost Mode";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self action:@selector(close)];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    return s == 0 ? @"Messages & DMs" : @"Feed & Tracking";
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    if (s == 1) return @"All changes apply immediately.\nOpen: 3-finger triple-tap anywhere.";
    return nil;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return s == 0 ? 8 : 7;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    int idx = (int)(ip.section == 0 ? ip.row : ip.row + 8);
    UITableViewCell *cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text     = @(kSettings[idx].title);
    cell.detailTextLabel.text = @(kSettings[idx].detail);
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UISwitch *sw = [UISwitch new];
    NSString *key = @(kSettings[idx].key);
    sw.on  = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    sw.tag = idx;
    [sw addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}

- (void)toggled:(UISwitch *)sw {
    NSString *key = @(kSettings[sw.tag].key);
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

// ─── Gesture helper ───────────────────────────────────────────────────────────
@interface GhostGestureTap : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
- (void)handleTap:(UITapGestureRecognizer *)tap;
@end

@implementation GhostGestureTap

+ (instancetype)shared {
    static GhostGestureTap *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [GhostGestureTap new]; });
    return s;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o {
    return YES;
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    UIWindow *win = tap.view.window;
    if (!win) return;

    GhostSettingsVC *ghostVC = [GhostSettingsVC new];
    extern UIViewController *doux_visualSettingsVC(void) __attribute__((weak));
    UIViewController *visualVC = (doux_visualSettingsVC ? doux_visualSettingsVC() : nil);

    UIViewController *rootVC;
    if (visualVC) {
        UITabBarController *tab = [UITabBarController new];
        UINavigationController *gNav = [[UINavigationController alloc] initWithRootViewController:ghostVC];
        UINavigationController *vNav = [[UINavigationController alloc] initWithRootViewController:visualVC];
        ghostVC.tabBarItem  = [[UITabBarItem alloc] initWithTitle:@"Ghost"  image:[UIImage systemImageNamed:@"eye.slash.fill"] tag:0];
        visualVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Visual" image:[UIImage systemImageNamed:@"sparkles"]       tag:1];
        tab.viewControllers = @[gNav, vNav];
        rootVC = tab;
    } else {
        rootVC = [[UINavigationController alloc] initWithRootViewController:ghostVC];
    }
    rootVC.modalPresentationStyle = UIModalPresentationFormSheet;

    UIViewController *top = win.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:rootVC animated:YES completion:nil];
}

@end

// ─── Gesture install ──────────────────────────────────────────────────────────
static void installGesture(void);
static void installGestureRetry(void) { installGesture(); }

static void installGesture(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
            if (![sc isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *w in ((UIWindowScene *)sc).windows) {
                if (!w.isHidden) { win = w; break; }
            }
            if (win) break;
        }
        if (!win) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ installGestureRetry(); });
            return;
        }
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:[GhostGestureTap shared]
            action:@selector(handleTap:)];
        tap.numberOfTapsRequired    = 3;
        tap.numberOfTouchesRequired = 3;
        tap.delegate = [GhostGestureTap shared];
        [win addGestureRecognizer:tap];
    });
}

// ─── Entry point ──────────────────────────────────────────────────────────────
__attribute__((constructor))
static void ghost_init(void) {
    // URL-level interception for NSURLSession.sharedSession
    [NSURLProtocol registerClass:[GhostProtocol class]];

    // Swizzle UILabel to hide "Seen at" timestamps
    swizzle_instance([UILabel class],
                     @selector(setText:),
                     @selector(doux_setText:));

    // Swizzle UIApplication sendEvent to drop screenshot events
    swizzle_instance([UIApplication class],
                     @selector(sendEvent:),
                     @selector(doux_sendEvent:));

    installGesture();
}
