// ghost_standalone.m
// Pure Objective-C ghost mode — zero Ellekit / substrate dependency.
// Intercepts ALL NSURLSession traffic (including TikTok's custom sessions)
// via NSURLSessionConfiguration swizzle + NSURLProtocol.
// Settings UI: 3-finger triple-tap anywhere in TikTok.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ─── Settings keys ────────────────────────────────────────────────────────────
#define K_READ    @"doux_ghost_read"
#define K_PROFILE @"doux_ghost_profile"
#define K_ONLINE  @"doux_ghost_online"
#define K_TYPING  @"doux_ghost_typing"

static BOOL gRead()    { return [[NSUserDefaults standardUserDefaults] boolForKey:K_READ];    }
static BOOL gProfile() { return [[NSUserDefaults standardUserDefaults] boolForKey:K_PROFILE]; }
static BOOL gOnline()  { return [[NSUserDefaults standardUserDefaults] boolForKey:K_ONLINE];  }
static BOOL gTyping()  { return [[NSUserDefaults standardUserDefaults] boolForKey:K_TYPING];  }

// ─── URL filter ───────────────────────────────────────────────────────────────
static BOOL ghostShouldBlock(NSString *url) {
    if (!url.length) return NO;

    if (gRead() && (
        [url containsString:@"mark_read"] ||
        [url containsString:@"markRead"]  ||
        [url containsString:@"/im/ack"]   ||
        [url containsString:@"clear_unread"] ||
        [url containsString:@"bulletin/clear"]
    )) return YES;

    if (gProfile() && (
        [url containsString:@"profile/view_record"] ||
        [url containsString:@"profile_view"]         ||
        [url containsString:@"profileviewscontrol"]
    )) return YES;

    if (gOnline() && (
        [url containsString:@"im/presence"]  ||
        [url containsString:@"online_status"] ||
        [url containsString:@"im/status"]
    )) return YES;

    if (gTyping() && (
        [url containsString:@"im/typing"]          ||
        [url containsString:@"typing_recommendation"]
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

// ─── Inject GhostProtocol into ALL NSURLSession instances ────────────────────
// TikTok creates custom NSURLSessionConfiguration — swizzling protocolClasses
// ensures our interceptor is active in every session.

@interface NSURLSessionConfiguration (GhostInject)
- (NSArray *)ghost_protocolClasses;
@end

@implementation NSURLSessionConfiguration (GhostInject)
- (NSArray *)ghost_protocolClasses {
    // calls original (implementations are swapped)
    NSArray *orig = [self ghost_protocolClasses];
    for (Class c in orig) {
        if (c == [GhostProtocol class]) return orig;
    }
    NSMutableArray *arr = [NSMutableArray arrayWithObject:[GhostProtocol class]];
    if (orig) [arr addObjectsFromArray:orig];
    return [arr copy];
}
@end

// ─── Settings UI ──────────────────────────────────────────────────────────────
@interface GhostSettingsVC : UITableViewController
@end

@implementation GhostSettingsVC {
    NSArray<NSString *> *_keys, *_titles, *_details;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Ghost Mode";
    _keys    = @[K_READ,                                K_PROFILE,                        K_ONLINE,                        K_TYPING];
    _titles  = @[@"Hide Read Receipts",                 @"Hide Profile Views",             @"Appear Offline",               @"Hide Typing Indicator"];
    _details = @[@"Others won't see that you've read",  @"Won't appear in their viewers",  @"Show yourself as offline",     @"Don't send typing events"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self action:@selector(close)];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 1; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return 4; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return @"Ghost Mode"; }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    return @"Changes take effect immediately.\nOpen: 3-finger triple-tap anywhere in TikTok.";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = _titles[ip.row];
    cell.detailTextLabel.text = _details[ip.row];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *sw = [UISwitch new];
    sw.on  = [[NSUserDefaults standardUserDefaults] boolForKey:_keys[ip.row]];
    sw.tag = ip.row;
    [sw addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}

- (void)toggled:(UISwitch *)sw {
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:_keys[sw.tag]];
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
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return YES; }
- (void)handleTap:(UITapGestureRecognizer *)tap {
    UIWindow *win = tap.view.window;
    if (!win) return;
    GhostSettingsVC *vc = [GhostSettingsVC new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    UIViewController *root = win.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    [root presentViewController:nav animated:YES completion:nil];
}
@end

// ─── Install gesture after app window is ready ────────────────────────────────
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

// ─── Library entry point ──────────────────────────────────────────────────────
__attribute__((constructor))
static void ghost_init(void) {
    // Register protocol globally (covers NSURLSession.sharedSession)
    [NSURLProtocol registerClass:[GhostProtocol class]];

    // Swizzle NSURLSessionConfiguration.protocolClasses so custom sessions
    // created by TikTok also route through GhostProtocol.
    Class cfg = [NSURLSessionConfiguration class];
    Method mo = class_getInstanceMethod(cfg, @selector(protocolClasses));
    Method ms = class_getInstanceMethod(cfg, @selector(ghost_protocolClasses));
    if (mo && ms) method_exchangeImplementations(mo, ms);

    // Install settings gesture when the app's window is ready.
    installGesture();
}
