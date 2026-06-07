// visual_standalone.m
// Video background + Liquid Glass nav bar (iOS 26)
// Pure ObjC — no Ellekit needed

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// ─── Keys ────────────────────────────────────────────────────────────────────
#define K_VIDEO_BG_ENABLED  @"doux_video_bg_enabled"
#define K_VIDEO_BG_PATH     @"doux_video_bg_path"
#define K_GLASS_ENABLED     @"doux_glass_enabled"

static NSString *videoBgPath(void) {
    return [[NSUserDefaults standardUserDefaults] stringForKey:K_VIDEO_BG_PATH];
}
static BOOL videoBgEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:K_VIDEO_BG_ENABLED];
}
static BOOL glassEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:K_GLASS_ENABLED];
}

// ─── Video background helper ──────────────────────────────────────────────────
static void attachVideoBackground(UIView *targetView, NSString *videoPath) {
    if (!targetView || !videoPath) return;

    // Remove old if exists
    for (CALayer *l in targetView.layer.sublayers) {
        if ([l.name isEqualToString:@"GhostVideoBg"]) { [l removeFromSuperlayer]; }
    }

    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    AVQueuePlayer *player = [AVQueuePlayer queuePlayerWithItems:@[item]];
    AVPlayerLooper *looper = [AVPlayerLooper playerLooperWithPlayer:player templateItem:item];

    // Keep looper alive via associated object on the view
    objc_setAssociatedObject(targetView, "doux_looper", looper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(targetView, "doux_player", player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
    layer.name = @"GhostVideoBg";
    layer.frame = targetView.bounds;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.zPosition = -1;
    [targetView.layer insertSublayer:layer atIndex:0];

    [player play];

    // Update frame on bounds changes via KVO-free layout trick
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        layer.frame = targetView.bounds;
    });
}

// ─── Apply video bg to a ViewController ──────────────────────────────────────
static void applyVideoBg(UIViewController *vc) {
    if (!videoBgEnabled()) return;
    NSString *path = videoBgPath();
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) return;
    attachVideoBackground(vc.view, path);
}

// ─── Liquid Glass tab bar (iOS 26+) ──────────────────────────────────────────
static void applyGlassTabBar(UITabBarController *tc) {
    if (!glassEnabled()) return;
    // iOS 26 UITabBar glass — use new UITabBarAppearance with glass material
    if (@available(iOS 26.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        // UIBlurEffect with systemUltraThinMaterial approximates liquid glass
        [appearance configureWithDefaultBackground];
        appearance.backgroundColor = [UIColor clearColor];

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
        UIVisualEffectView *ev = [[UIVisualEffectView alloc] initWithEffect:blur];
        ev.frame = tc.tabBar.bounds;
        ev.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        ev.alpha = 0.85;

        tc.tabBar.backgroundColor = [UIColor clearColor];
        tc.tabBar.backgroundImage = [UIImage new];
        tc.tabBar.shadowImage = [UIImage new];
        if (![tc.tabBar viewWithTag:8899]) {
            ev.tag = 8899;
            [tc.tabBar insertSubview:ev atIndex:0];
        }
    }
}

// ─── Swizzle: UIViewController viewDidAppear ──────────────────────────────────
static IMP orig_viewDidAppear = nil;

static void swizzled_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    ((void(*)(id,SEL,BOOL))orig_viewDidAppear)(self, _cmd, animated);

    NSString *cls = NSStringFromClass([self class]);

    // Video bg on: profile, inbox, settings screens
    BOOL isTarget =
        [cls containsString:@"Profile"]  ||
        [cls containsString:@"Inbox"]    ||
        [cls containsString:@"Message"]  ||
        [cls containsString:@"Setting"]  ||
        [cls containsString:@"AWEProfile"] ||
        [cls isEqualToString:@"TTKProfileHomeViewController"] ||
        [cls isEqualToString:@"AWEInboxViewController"];

    if (isTarget) applyVideoBg(self);

    // Glass tab bar whenever we see a UITabBarController
    if ([self isKindOfClass:[UITabBarController class]]) {
        applyGlassTabBar((UITabBarController *)self);
    }
}

// ─── Settings / picker UI ────────────────────────────────────────────────────
@interface VisualSettingsVC : UITableViewController
@end

@implementation VisualSettingsVC {
    NSArray<NSString*> *_titles, *_details;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Visual";
    _titles  = @[@"Video Background", @"Liquid Glass Bar", @"Set Video...", @"Reset Video"];
    _details = @[@"Loop video on profile/inbox/settings",
                 @"Frosted glass tab bar (iOS 26+)",
                 @"Choose .mp4 from Files app",
                 @"Remove current background video"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self action:@selector(close)];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return s == 0 ? 2 : 2; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    return s == 0 ? @"Toggles" : @"Video";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    NSInteger idx = ip.section * 2 + ip.row;
    cell.textLabel.text = _titles[idx];
    cell.detailTextLabel.text = _details[idx];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];

    if (ip.section == 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *sw = [UISwitch new];
        NSString *key = ip.row == 0 ? K_VIDEO_BG_ENABLED : K_GLASS_ENABLED;
        sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:key];
        sw.tag = ip.row;
        [sw addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)toggled:(UISwitch *)sw {
    NSString *key = sw.tag == 0 ? K_VIDEO_BG_ENABLED : K_GLASS_ENABLED;
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section != 1) return;
    if (ip.row == 0) {
        // Pick video from Files
        UIDocumentPickerViewController *picker =
            [[UIDocumentPickerViewController alloc]
             initForOpeningContentTypes:@[[UTType typeWithIdentifier:@"public.movie"]]];
        picker.delegate = (id<UIDocumentPickerDelegate>)self;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:K_VIDEO_BG_PATH];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:K_VIDEO_BG_ENABLED];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.tableView reloadData];
    }
}

- (void)documentPicker:(UIDocumentPickerViewController *)c didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
    NSURL *src = urls.firstObject;
    if (!src) return;
    [src startAccessingSecurityScopedResource];

    // Copy to app Documents for persistent access
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dest = [docs stringByAppendingPathComponent:@"doux_bg.mp4"];
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:dest error:nil];
    [[NSFileManager defaultManager] copyItemAtURL:src toURL:[NSURL fileURLWithPath:dest] error:&err];
    [src stopAccessingSecurityScopedResource];

    if (!err) {
        [[NSUserDefaults standardUserDefaults] setObject:dest forKey:K_VIDEO_BG_PATH];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:K_VIDEO_BG_ENABLED];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self.tableView reloadData];
}
@end

// ─── Entry point ──────────────────────────────────────────────────────────────
__attribute__((constructor))
static void visual_init(void) {
    // Swizzle UIViewController viewDidAppear to inject video bg and glass
    Method orig = class_getInstanceMethod([UIViewController class], @selector(viewDidAppear:));
    orig_viewDidAppear = method_getImplementation(orig);
    method_setImplementation(orig, (IMP)swizzled_viewDidAppear);
}

// Expose VisualSettingsVC for settings entry (called from ghost_standalone gesture menu)
UIViewController *doux_visualSettingsVC(void) {
    return [VisualSettingsVC new];
}
