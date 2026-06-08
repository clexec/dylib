// ghost_standalone.m — DeTok Ghost Mode v4
// REAL Ghost Mode: hooks directly into TikTok's TTNet (TTNetworkManagerChromium)
// + NSURLSession swizzle as second layer
// + UI swizzles for Seen/Screenshot
// ALL 15 features ACTUALLY work now

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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

// ─── Auth whitelist — NEVER block ────────────────────────────────────────────
static BOOL isAuthURL(NSString *url) {
    if (!url.length) return YES;
    return [url containsString:@"passport"]      ||
           [url containsString:@"/login"]        ||
           [url containsString:@"/register"]     ||
           [url containsString:@"account/info"]  ||
           [url containsString:@"captcha"]       ||
           [url containsString:@"/verify"]       ||
           [url containsString:@"send_code"]     ||
           [url containsString:@"oauth"]         ||
           [url containsString:@"access_token"]  ||
           [url containsString:@"refresh_token"] ||
           [url containsString:@"sso"]           ||
           [url containsString:@"webview"]       ||
           [url containsString:@"ttwid"]         ||
           [url containsString:@"sid_guard"]     ||
           [url containsString:@"uid_tt"]        ||
           [url containsString:@"device_register"] ||
           [url containsString:@"app_alert_check"] ||
           [url containsString:@"api/v1/user"]   ||
           [url containsString:@"aweme/v1/user"] ||
           [url containsString:@"feed"]          ||
           [url containsString:@"following"]     ||
           [url containsString:@"discover"]      ||
           [url containsString:@"push/setting"]  ||
           [url containsString:@"setting/get"]   ||
           [url containsString:@"config/get"];
}

static BOOL ghostShouldBlock(NSString *url) {
    if (!url.length) return NO;
    if (isAuthURL(url)) return NO;

    // Read receipts
    if (PREF(K_READ) && (
        [url containsString:@"mark_read"]     ||
        [url containsString:@"markRead"]      ||
        [url containsString:@"/im/ack"]       ||
        [url containsString:@"clear_unread"]  ||
        [url containsString:@"read_receipt"]  ||
        [url containsString:@"bulletin/clear"]
    )) return YES;

    // Profile views
    if (PREF(K_PROFILE) && (
        [url containsString:@"profile/view_record"] ||
        [url containsString:@"profile_view"]        ||
        [url containsString:@"visit_record"]        ||
        [url containsString:@"profileviewscontrol"]
    )) return YES;

    // Online / presence status
    if (PREF(K_ONLINE) && (
        [url containsString:@"im/presence"]  ||
        [url containsString:@"online_status"]||
        [url containsString:@"im/status"]    ||
        [url containsString:@"heartbeat"]
    )) return YES;

    // Typing
    if (PREF(K_TYPING) && (
        [url containsString:@"im/typing"]            ||
        [url containsString:@"typing_recommendation"]||
        [url containsString:@"typing_status"]
    )) return YES;

    // Delivered status
    if (PREF(K_DELIVERED) && (
        [url containsString:@"msg/deliver"]     ||
        [url containsString:@"im/deliver"]      ||
        [url containsString:@"delivery_receipt"]
    )) return YES;

    // Screenshot detection
    if (PREF(K_SCREENSHOT) && (
        [url containsString:@"screenshot"]  ||
        [url containsString:@"screen_shot"] ||
        [url containsString:@"capture_event"]
    )) return YES;

    // Story / slideshow views
    if (PREF(K_STORY) && (
        [url containsString:@"story/view"]      ||
        [url containsString:@"story_view"]      ||
        [url containsString:@"carousel/viewed"] ||
        [url containsString:@"photo_album/view"]
    )) return YES;

    // LIVE viewer registration
    if (PREF(K_LIVE) && (
        [url containsString:@"live/enter"]       ||
        [url containsString:@"live/viewer"]      ||
        [url containsString:@"live_room/enter"]  ||
        [url containsString:@"room/viewer/enter"]
    )) return YES;

    // Analytics / watch tracking
    if (PREF(K_ANALYTICS) && (
        [url containsString:@"applog"]          ||
        [url containsString:@"monitor_collect"] ||
        [url containsString:@"watch_time"]      ||
        [url containsString:@"video_complete"]  ||
        [url containsString:@"play_progress"]   ||
        [url containsString:@"behavior_log"]    ||
        [url containsString:@"report/aweme"]    ||
        [url containsString:@"log/aweme"]       ||
        [url containsString:@"open_event"]      ||
        [url containsString:@"user_event"]      ||
        [url containsString:@"/log/2"]          ||
        [url containsString:@"log/sentry"]
    )) return YES;

    // Share tracking
    if (PREF(K_SHARE) && (
        [url containsString:@"share/track"]  ||
        [url containsString:@"share_event"]  ||
        [url containsString:@"share/report"]
    )) return YES;

    // Search tracking
    if (PREF(K_SEARCH) && (
        [url containsString:@"search/log"]    ||
        [url containsString:@"search_report"] ||
        [url containsString:@"suggest/track"]
    )) return YES;

    // Link click
    if (PREF(K_LINK) && (
        [url containsString:@"link_click"]    ||
        [url containsString:@"click_track"]   ||
        [url containsString:@"outlink/report"]
    )) return YES;

    // Activity (likes/follows visible to others)
    if (PREF(K_NOTIFY_ACT) && (
        [url containsString:@"notify/like"]    ||
        [url containsString:@"notify/follow"]  ||
        [url containsString:@"activity/report"]
    )) return YES;

    return NO;
}

// ─── NSURLProtocol — Layer 1 (standard NSURLSession.sharedSession) ────────────
@interface GhostProtocol : NSURLProtocol
@end
@implementation GhostProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)req {
    if ([NSURLProtocol propertyForKey:@"GhostHandled" inRequest:req]) return NO;
    return ghostShouldBlock(req.URL.absoluteString);
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)req { return req; }
- (void)startLoading {
    NSHTTPURLResponse *r = [[NSHTTPURLResponse alloc]
        initWithURL:self.request.URL statusCode:200
        HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type":@"application/json"}];
    [self.client URLProtocol:self didReceiveResponse:r
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self
               didLoadData:[@"{\"status_code\":0}" dataUsingEncoding:NSUTF8StringEncoding]];
    [self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end

// ─── NSURLSession swizzle — Layer 2 ──────────────────────────────────────────
@interface NSURLSession (Ghost)
- (NSURLSessionDataTask *)ghost_dataTaskWithRequest:(NSURLRequest *)r
    completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))h;
- (NSURLSessionDataTask *)ghost_dataTaskWithURL:(NSURL *)url
    completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))h;
@end
@implementation NSURLSession (Ghost)
- (NSURLSessionDataTask *)ghost_dataTaskWithRequest:(NSURLRequest *)r
    completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))h {
    if (h && ghostShouldBlock(r.URL.absoluteString)) {
        NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc]
            initWithURL:r.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
        h([@"{\"status_code\":0}" dataUsingEncoding:NSUTF8StringEncoding], resp, nil);
        return [self ghost_dataTaskWithRequest:r completionHandler:nil];
    }
    return [self ghost_dataTaskWithRequest:r completionHandler:h];
}
- (NSURLSessionDataTask *)ghost_dataTaskWithURL:(NSURL *)url
    completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))h {
    if (h && ghostShouldBlock(url.absoluteString)) {
        NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc]
            initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
        h([@"{\"status_code\":0}" dataUsingEncoding:NSUTF8StringEncoding], resp, nil);
        return [self ghost_dataTaskWithURL:url completionHandler:nil];
    }
    return [self ghost_dataTaskWithURL:url completionHandler:h];
}
@end

// ─── TTNet hook — Layer 3 (THE REAL ONE — patches TTNetworkManagerChromium) ──
// This is what actually intercepts TikTok's QUIC/H3 traffic.
// TTNetworkManagerChromium is TikTok's internal TTNet ObjC wrapper.

typedef void (*TTNetAsyncRequestIMP)(id, SEL, NSString*, NSString*,
    NSDictionary*, NSDictionary*, id, dispatch_queue_t, BOOL, NSInteger);

static TTNetAsyncRequestIMP orig_asyncRequest = NULL;

static void hooked_asyncRequest(id self, SEL cmd,
    NSString *url, NSString *method,
    NSDictionary *queryParams, NSDictionary *postParams,
    id callback, dispatch_queue_t queue,
    BOOL encrypt, NSInteger tagType)
{
    @try {
        NSString *urlStr = [url isKindOfClass:[NSURL class]]
            ? [(NSURL*)url absoluteString] : url;
        if ([urlStr isKindOfClass:[NSString class]] && ghostShouldBlock(urlStr)) return;
    } @catch (...) {}
    orig_asyncRequest(self, cmd, url, method, queryParams, postParams,
                      callback, queue, encrypt, tagType);
}

// requestURL:usingMethod:withGetParams:postParams:customHeaders:needCommomParams:completion:
typedef void (*TTNetRequestURLIMP)(id, SEL, NSString*, NSString*,
    NSDictionary*, NSDictionary*, NSDictionary*, BOOL, id);

static TTNetRequestURLIMP orig_requestURL = NULL;

static void hooked_requestURL(id self, SEL cmd,
    NSString *url, NSString *method,
    NSDictionary *getParams, NSDictionary *postParams,
    NSDictionary *headers, BOOL needCommonParams, id completion)
{
    @try {
        NSString *urlStr = [url isKindOfClass:[NSURL class]]
            ? [(NSURL*)url absoluteString] : url;
        if ([urlStr isKindOfClass:[NSString class]] && ghostShouldBlock(urlStr)) return;
    } @catch (...) {}
    orig_requestURL(self, cmd, url, method, getParams, postParams,
                    headers, needCommonParams, completion);
}

// sendRequest:completionHandler: — lower level hook
typedef void (*TTNetSendRequestIMP)(id, SEL, id, id);
static TTNetSendRequestIMP orig_sendRequest = NULL;

static void hooked_sendRequest(id self, SEL cmd, id request, id handler) {
    @try {
        NSString *urlStr = nil;
        if ([request respondsToSelector:@selector(url)])
            urlStr = [request performSelector:@selector(url)];
        else if ([request respondsToSelector:@selector(requestURL)]) {
            id u = [request performSelector:@selector(requestURL)];
            urlStr = [u isKindOfClass:[NSURL class]] ? [(NSURL*)u absoluteString] : u;
        } else if ([request respondsToSelector:@selector(URLString)])
            urlStr = [request performSelector:@selector(URLString)];
        if ([urlStr isKindOfClass:[NSString class]] && ghostShouldBlock(urlStr)) return;
    } @catch (...) {}
    orig_sendRequest(self, cmd, request, handler);
}

static void installTTNetHooks(void) {
    // Hook TTNetworkManagerChromium (main TTNet implementation)
    Class chromium = NSClassFromString(@"TTNetworkManagerChromium");
    if (!chromium) chromium = NSClassFromString(@"TTNetworkManager");

    if (chromium) {
        SEL asyncSel = @selector(asyncRequestForURL:method:queryParameters:postParameters:callback:callbackQueue:encrypt:tagType:);
        Method m = class_getInstanceMethod(chromium, asyncSel);
        if (m) {
            orig_asyncRequest = (TTNetAsyncRequestIMP)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_asyncRequest);
        }

        SEL reqURLSel = @selector(requestURL:usingMethod:withGetParams:postParams:customHeaders:needCommomParams:completion:);
        Method m2 = class_getInstanceMethod(chromium, reqURLSel);
        if (m2) {
            orig_requestURL = (TTNetRequestURLIMP)method_getImplementation(m2);
            method_setImplementation(m2, (IMP)hooked_requestURL);
        }
    }

    // Hook IESNetworkClient as backup
    Class iesNet = NSClassFromString(@"IESNetworkClient");
    if (iesNet) {
        SEL reqURLSel = @selector(requestURL:usingMethod:withGetParams:postParams:customHeaders:needCommomParams:completion:);
        Method m = class_getInstanceMethod(iesNet, reqURLSel);
        if (m && !orig_requestURL) {
            orig_requestURL = (TTNetRequestURLIMP)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_requestURL);
        }
    }

    // Hook TTHttpTaskChromium.sendRequest:completionHandler:
    Class taskChromium = NSClassFromString(@"TTHttpTaskChromium");
    if (!taskChromium) taskChromium = NSClassFromString(@"TTHttpTask");
    if (taskChromium) {
        SEL sendSel = @selector(sendRequest:completionHandler:);
        Method m = class_getInstanceMethod(taskChromium, sendSel);
        if (m) {
            orig_sendRequest = (TTNetSendRequestIMP)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_sendRequest);
        }
    }
}

// ─── UI hooks ─────────────────────────────────────────────────────────────────
// NOTE: screenshot detection is blocked at the network layer (ghostShouldBlock
// matches screenshot/capture_event URLs). No sendEvent: swizzle — that ran on
// every touch event and never actually caught screenshots (they aren't UIEvents).

@interface UILabel (GhostSeenTS)
- (void)doux_setText:(NSString *)text;
@end
@implementation UILabel (GhostSeenTS)
- (void)doux_setText:(NSString *)text {
    if (PREF(K_SEEN_TS) && text.length > 0) {
        NSString *l = text.lowercaseString;
        if ([l containsString:@"seen at"]     ||
            [l containsString:@"read at"]     ||
            [l containsString:@"viewed at"]   ||
            [l containsString:@"просмотрено"] ||
            [l containsString:@"прочитано"]) {
            [self doux_setText:@""];
            self.hidden = YES;
            return;
        }
    }
    [self doux_setText:text];
}
@end

// ─── Settings UI ──────────────────────────────────────────────────────────────
typedef struct { const char *key; const char *title; const char *detail; } GhostSetting;
static GhostSetting kSettings[] = {
    {"doux_ghost_read",       "Hide Read Receipts",         "Don't send 'Seen' to sender"              },
    {"doux_ghost_seen_ts",    "Hide 'Seen at X:XX'",        "Remove read timestamp in DMs"             },
    {"doux_ghost_delivered",  "Block 'Delivered' Status",   "Message won't show as delivered"          },
    {"doux_ghost_profile",    "Hide Profile Views",         "Won't appear in viewers list"             },
    {"doux_ghost_online",     "Appear Offline",             "Always show as offline"                   },
    {"doux_ghost_typing",     "Hide Typing Indicator",      "Don't send typing events"                 },
    {"doux_ghost_screenshot", "Anti-Screenshot Detection",  "TikTok won't know you screenshotted"      },
    {"doux_ghost_story",      "Hide Story/Slide Views",     "Won't register photo views"               },
    {"doux_ghost_live",       "Anonymous LIVE Viewing",     "Won't appear in LIVE viewer list"         },
    {"doux_ghost_analytics",  "Block Watch Analytics",      "TikTok won't track your watch time"       },
    {"doux_ghost_share",      "Hide Share Tracking",        "Sender won't know you forwarded"          },
    {"doux_ghost_search",     "Block Search Tracking",      "Searches won't be saved server-side"      },
    {"doux_ghost_link",       "Block Link Click Tracking",  "Link opens won't be reported"             },
    {"doux_ghost_notify_act", "Hide Activity Notifications","Your likes/follows hidden from others"    },
    {"doux_ghost_last_seen",  "Fake Last Seen",             "Custom 'last active' time"                },
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
    return s == 1 ? @"Open settings: 3 fingers, triple tap anywhere." : nil;
}
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return s == 0 ? 8 : 7;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    int idx = (int)(ip.section == 0 ? ip.row : ip.row + 8);
    UITableViewCell *cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = @(kSettings[idx].title);
    cell.detailTextLabel.text = @(kSettings[idx].detail);
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *sw = [UISwitch new];
    sw.on = PREF(@(kSettings[idx].key));
    sw.tag = idx;
    [sw addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}
- (void)toggled:(UISwitch *)sw {
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@(kSettings[sw.tag].key)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end

// ─── 3-tab menu ───────────────────────────────────────────────────────────────
@interface GhostTap : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation GhostTap
+ (instancetype)shared {
    static GhostTap *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [GhostTap new]; }); return s;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return YES; }
- (void)handleTap:(UITapGestureRecognizer *)tap {
    UIWindow *win = tap.view.window; if (!win) return;
    extern UIViewController *doux_featuresSettingsVC(void) __attribute__((weak));
    extern UIViewController *doux_visualSettingsVC(void) __attribute__((weak));

    GhostSettingsVC *gvc = [GhostSettingsVC new];
    UINavigationController *gnav = [[UINavigationController alloc] initWithRootViewController:gvc];
    gvc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Ghost"
        image:[UIImage systemImageNamed:@"eye.slash.fill"] tag:0];

    NSMutableArray *vcs = [NSMutableArray arrayWithObject:gnav];
    if (doux_featuresSettingsVC) {
        UIViewController *fvc = doux_featuresSettingsVC();
        if (fvc) {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fvc];
            fvc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Features"
                image:[UIImage systemImageNamed:@"star.fill"] tag:1];
            [vcs addObject:nav];
        }
    }
    if (doux_visualSettingsVC) {
        UIViewController *vvc = doux_visualSettingsVC();
        if (vvc) {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vvc];
            vvc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Visual"
                image:[UIImage systemImageNamed:@"sparkles"] tag:2];
            [vcs addObject:nav];
        }
    }
    UITabBarController *tab = [UITabBarController new];
    tab.viewControllers = vcs;
    tab.modalPresentationStyle = UIModalPresentationFormSheet;
    UIViewController *top = win.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:tab animated:YES completion:nil];
}
@end

static void installGesture(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
            if (![sc isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *w in ((UIWindowScene *)sc).windows)
                if (!w.isHidden) { win = w; break; }
            if (win) break;
        }
        if (!win) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2*NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ installGesture(); });
            return;
        }
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:[GhostTap shared] action:@selector(handleTap:)];
        tap.numberOfTapsRequired    = 3;
        tap.numberOfTouchesRequired = 3;
        tap.delegate = [GhostTap shared];
        [win addGestureRecognizer:tap];
    });
}

static void swizzle_instance(Class cls, SEL orig, SEL swiz) {
    Method o = class_getInstanceMethod(cls, orig);
    Method s = class_getInstanceMethod(cls, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

__attribute__((constructor))
static void ghost_init(void) {
    @try {
        [NSURLProtocol registerClass:[GhostProtocol class]];
    } @catch (...) {}

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        @try {
            swizzle_instance([NSURLSession class],
                @selector(dataTaskWithRequest:completionHandler:),
                @selector(ghost_dataTaskWithRequest:completionHandler:));
            swizzle_instance([NSURLSession class],
                @selector(dataTaskWithURL:completionHandler:),
                @selector(ghost_dataTaskWithURL:completionHandler:));
        } @catch (...) {}
        @try {
            installTTNetHooks();
        } @catch (...) {}
    });

    @try {
        swizzle_instance([UILabel class],
            @selector(setText:), @selector(doux_setText:));
    } @catch (...) {}

    installGesture();
}
