// features_standalone.m
// DeTok v1.2 — All features: Download, Feed, Profile, Security
// Pure ObjC — no Ellekit / no Theos needed
// Class names verified from BHTikTokPlusPlus Tweak.x + TikTokHeaders.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// ─── Settings keys ────────────────────────────────────────────────────────────
#define FPREF(k) [[NSUserDefaults standardUserDefaults] boolForKey:(k)]
#define FVAL(k)  [[NSUserDefaults standardUserDefaults] floatForKey:(k)]

#define K_DOWNLOAD_BTN    @"dt_download_btn"
#define K_HIDE_ADS        @"dt_hide_ads"
#define K_PROGRESS_BAR    @"dt_progress_bar"
#define K_AUTO_PLAY       @"dt_auto_play"
#define K_STOP_LOOP       @"dt_stop_loop"
#define K_SKIP_RECS       @"dt_skip_recs"
#define K_SPEED_EN        @"dt_speed_enabled"
#define K_SPEED_VAL       @"dt_speed_value"
#define K_UPLOAD_REGION   @"dt_upload_region"
#define K_TRANSPARENT_C   @"dt_transparent_comments"
#define K_SHOW_USERNAME   @"dt_show_username"
#define K_NO_REFRESH      @"dt_no_pull_refresh"
#define K_NO_SENSITIVE    @"dt_no_sensitive"
#define K_NO_WARNINGS     @"dt_no_warnings"
#define K_NO_LIVE         @"dt_no_live"
#define K_PROFILE_SAVE    @"dt_profile_save"
#define K_PROFILE_COPY    @"dt_profile_copy"
#define K_VIDEO_LIKES     @"dt_video_likes"
#define K_VIDEO_DATE      @"dt_video_date"
#define K_VIDEO_COUNT     @"dt_video_count"
#define K_APP_LOCK        @"dt_app_lock"
#define K_LIKE_CONFIRM    @"dt_like_confirm"
#define K_FOLLOW_CONFIRM  @"dt_follow_confirm"

// ─── Forward declarations ─────────────────────────────────────────────────────
@class AWEAwemeModel, AWEUserModel, AWEAwemeStatisticsModel, AWEVideoModel,
       AWEURLModel, AWEPhotoAlbumModel, AWEPhotoAlbumPhoto, AWEMusicModel;

@interface AWEURLModel : NSObject
@property(retain, nonatomic) NSArray *originURLList;
- (NSURL *)bestURLtoDownload;
- (NSString *)bestURLtoDownloadFormat;
@end

@interface AWEVideoModel : NSObject
@property(readonly, nonatomic) AWEURLModel *playURL;
@end

@interface AWEMusicModel : NSObject
@property(readonly, nonatomic) AWEURLModel *playURL;
@end

@interface AWEPhotoAlbumPhoto : NSObject
@property(readonly, nonatomic) AWEURLModel *originPhotoURL;
@end

@interface AWEPhotoAlbumModel : NSObject
@property(readonly, nonatomic) NSArray *photos;
@end

@interface AWEAwemeStatisticsModel : NSObject
@property(nonatomic, strong) NSNumber *diggCount;
@end

@interface AWEUserModel : NSObject
@property(nonatomic, copy) NSString *nickname;
@property(nonatomic, copy) NSString *socialName;
@property(nonatomic, copy) NSString *signature;
@property(nonatomic, strong) NSNumber *visibleVideosCount;
@end

@interface AWEAwemeModel : NSObject
@property(nonatomic) BOOL isAds;
@property(retain, nonatomic) AWEVideoModel *video;
@property(retain, nonatomic) AWEMusicModel *music;
@property(nonatomic, copy) NSString *itemID;
@property(retain, nonatomic) AWEPhotoAlbumModel *photoAlbum;
@property(nonatomic, copy) NSString *region;
@property(nonatomic, strong) AWEAwemeStatisticsModel *statistics;
@property(nonatomic, strong) NSNumber *createTime;
@property(nonatomic, strong) AWEUserModel *author;
@property(nonatomic, assign) BOOL isUserRecommendBigCard;
+ (id)liveStreamURLJSONTransformer;
+ (id)relatedLiveJSONTransformer;
+ (id)rawModelFromLiveRoomModel:(id)arg1;
+ (id)aweLiveRoom_subModelPropertyKey;
- (void)live_callInitWithDictyCategoryMethod:(id)arg1;
- (BOOL)progressBarDraggable;
- (BOOL)progressBarVisible;
@end

@interface AWENewFeedTableViewController : UIViewController
@property(nonatomic, assign, readonly) AWEAwemeModel *currentAweme;
- (void)scrollToNextVideo;
- (BOOL)disablePullToRefreshGestureRecognizer;
@end

@interface AWEPlayVideoPlayerController : NSObject
@property(nonatomic, weak) UIViewController *container;
- (void)playerWillLoopPlaying:(id)arg1;
- (BOOL)loop;
- (void)setLoop:(BOOL)arg1;
- (void)containerDidFullyDisplayWithReason:(NSInteger)arg1;
@end

@interface AWEMaskInfoModel : NSObject
- (BOOL)showMask;
- (void)setShowMask:(BOOL)v;
@end

@interface AWEFeedVideoButton : UIButton
@property(nonatomic, copy) NSString *imageNameString;
@end

@interface AWECommentPanelCell : UITableViewCell
- (void)onLikeAction:(id)arg1;
- (void)onDislikeAction:(id)arg1;
@end

@interface AWEPlayInteractionUserAvatarElement : NSObject
- (void)onFollowViewClicked:(id)sender;
@end

@interface AWEPlayInteractionWarningElementView : UIView
- (id)warningImage;
- (id)warningLabel;
@end

@interface TTKCommentPanelViewController : UIViewController
@end

@interface AWETextInputController : NSObject
- (NSUInteger)maxLength;
@end

@interface AWEProfileEditTextViewController : UIViewController
- (NSInteger)maxTextLength;
@end

@interface TTKProfileRootView : UIView
@end

@interface TTKProfileOtherViewController : UIViewController
@property(nonatomic, strong) AWEUserModel *user;
@end

@interface UIView (AWEVC)
@property(retain, nonatomic) UIViewController *yy_viewController;
@end

@interface AWEFeedCellViewController : UIViewController
@property(nonatomic, strong) AWEAwemeModel *model;
@end

@interface TUXLabel : UILabel
@end

@interface AWEPlayInteractionAuthorUserNameButton : UIView
@end

@interface AWEPlayInteractionAuthorView : UIView
@end

@interface AWEAwemeACLItem : NSObject
- (void)setWatermarkType:(NSUInteger)arg1;
- (NSUInteger)watermarkType;
@end

@interface TIKTOKProfileHeaderView : UIView
@end

@interface AWEUserWorkCollectionViewCell : UICollectionViewCell
@property(nonatomic, strong) AWEAwemeModel *model;
@property(nonatomic, strong) UIView *contentView;
@end

@interface AWELiveFeedEntranceView : UIView
- (void)switchStateWithTapped:(BOOL)arg1;
@end

@interface AWEFeedViewTemplateCell : UIView
- (void)configWithModel:(id)model;
- (void)configureWithModel:(id)model;
@end

@interface TTKMediaSpeedControlService : NSObject
- (void)setPlaybackRate:(CGFloat)rate;
@end

// ─── Helpers ──────────────────────────────────────────────────────────────────
static void dt_swizzle(Class cls, SEL orig, SEL swiz) {
    Method o = class_getInstanceMethod(cls, orig);
    Method s = class_getInstanceMethod(cls, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

static void dt_swizzle_class(Class cls, SEL orig, SEL swiz) {
    Method o = class_getClassMethod(cls, orig);
    Method s = class_getClassMethod(cls, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

static UIViewController *dt_topVC(void) {
    UIWindow *win = nil;
    for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
        if ([sc isKindOfClass:[UIWindowScene class]])
            for (UIWindow *w in ((UIWindowScene *)sc).windows)
                if (!w.isHidden) { win = w; break; }
        if (win) break;
    }
    if (!win) win = [UIApplication sharedApplication].keyWindow;
    UIViewController *vc = win.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    if ([vc isKindOfClass:[UINavigationController class]])
        vc = ((UINavigationController *)vc).visibleViewController ?: vc;
    return vc;
}

static void dt_showAlert(NSString *title, NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *a = [UIAlertController
            alertControllerWithTitle:title message:msg
            preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault handler:nil]];
        [dt_topVC() presentViewController:a animated:YES completion:nil];
    });
}

static void dt_confirm(NSString *msg, void (^ok)(void)) {
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"DeTok" message:msg
        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Yes"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *_){ ok(); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"No"
        style:UIAlertActionStyleCancel handler:nil]];
    [dt_topVC() presentViewController:a animated:YES completion:nil];
}

// ─── Download ────────────────────────────────────────────────────────────────
static void dt_downloadURL(NSURL *url, BOOL isVideo) {
    if (!url) return;
    UIAlertController *hud = [UIAlertController
        alertControllerWithTitle:@"Downloading…" message:nil
        preferredStyle:UIAlertControllerStyleAlert];
    [dt_topVC() presentViewController:hud animated:YES completion:nil];

    [[NSURLSession.sharedSession downloadTaskWithURL:url
        completionHandler:^(NSURL *tmp, NSURLResponse *r, NSError *e) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud dismissViewControllerAnimated:NO completion:^{
                if (e || !tmp) {
                    dt_showAlert(@"Error", e.localizedDescription ?: @"Download failed");
                    return;
                }
                NSString *ext = isVideo ? @"mp4" : @"mp3";
                NSString *dest = [NSTemporaryDirectory()
                    stringByAppendingPathComponent:
                    [[NSUUID.UUID.UUIDString stringByAppendingString:@"."] stringByAppendingString:ext]];
                [[NSFileManager defaultManager] moveItemAtURL:tmp
                    toURL:[NSURL fileURLWithPath:dest] error:nil];
                if (isVideo) {
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        [PHAssetChangeRequest
                            creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:dest]];
                    } completionHandler:^(BOOL ok, NSError *err) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            dt_showAlert(@"DeTok", ok ? @"Video saved!" : @"Save failed");
                        });
                    }];
                } else {
                    NSURL *fileURL = [NSURL fileURLWithPath:dest];
                    UIActivityViewController *share = [[UIActivityViewController alloc]
                        initWithActivityItems:@[fileURL] applicationActivities:nil];
                    [dt_topVC() presentViewController:share animated:YES completion:nil];
                }
            }];
        });
    }] resume];
}

static void dt_downloadVideoHD(NSString *itemID) {
    if (!itemID.length) return;
    NSString *s = [NSString stringWithFormat:@"https://tikwm.com/video/media/hdplay/%@.mp4", itemID];
    dt_downloadURL([NSURL URLWithString:s], YES);
}

static NSString *dt_flagEmoji(NSString *code) {
    if (code.length != 2) return @"";
    uint32_t a = [code.uppercaseString characterAtIndex:0] + 0x1F1E6 - 'A';
    uint32_t b = [code.uppercaseString characterAtIndex:1] + 0x1F1E6 - 'A';
    return [[[NSString alloc] initWithBytes:&a length:4 encoding:NSUTF32LittleEndianStringEncoding]
        stringByAppendingString:
        [[NSString alloc] initWithBytes:&b length:4 encoding:NSUTF32LittleEndianStringEncoding]];
}

static NSString *dt_formatNumber(NSInteger n) {
    if (n >= 1000000) return [NSString stringWithFormat:@"%.1fM", n / 1000000.0];
    if (n >= 1000)    return [NSString stringWithFormat:@"%.1fK", n / 1000.0];
    return [NSString stringWithFormat:@"%ld", (long)n];
}

static NSString *dt_formatDate(NSTimeInterval ts) {
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:ts];
    NSDateFormatter *f = [NSDateFormatter new];
    f.dateFormat = @"dd.MM.yy";
    return [f stringFromDate:d];
}

// ─── App Lock ─────────────────────────────────────────────────────────────────
static BOOL _dt_lockShown = NO;
static void dt_showAppLock(void) {
    if (!FPREF(K_APP_LOCK) || _dt_lockShown) return;
    _dt_lockShown = YES;
    LAContext *ctx = [LAContext new];
    NSError *err;
    if ([ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&err]) {
        [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:@"Unlock DeTok"
                      reply:^(BOOL success, NSError *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) { _dt_lockShown = NO; dt_showAppLock(); }
            });
        }];
    }
}

// ─── Download action sheet ────────────────────────────────────────────────────
static void dt_showDownloadSheet(AWEAwemeModel *model) {
    UIAlertController *sheet = [UIAlertController
        alertControllerWithTitle:@"DeTok Download" message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];

    NSString *itemID = model.itemID;
    BOOL hasPhotos = model.photoAlbum.photos.count > 0;

    if (!hasPhotos) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Video HD (no watermark)"
            style:UIAlertActionStyleDefault handler:^(id _) {
            dt_downloadVideoHD(itemID);
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Video (original)"
            style:UIAlertActionStyleDefault handler:^(id _) {
            NSURL *u = [model.video.playURL bestURLtoDownload];
            dt_downloadURL(u, YES);
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Audio (MP3)"
            style:UIAlertActionStyleDefault handler:^(id _) {
            AWEMusicModel *music = (AWEMusicModel *)model.music;
            NSURL *u = [music.playURL bestURLtoDownload];
            dt_downloadURL(u, NO);
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Copy video link"
            style:UIAlertActionStyleDefault handler:^(id _) {
            NSURL *u = [model.video.playURL bestURLtoDownload];
            [UIPasteboard generalPasteboard].string = u.absoluteString;
            dt_showAlert(@"DeTok", @"Link copied!");
        }]];
    } else {
        // Slideshow — download all photos
        [sheet addAction:[UIAlertAction actionWithTitle:@"Download all photos"
            style:UIAlertActionStyleDefault handler:^(id _) {
            NSArray *photos = model.photoAlbum.photos;
            for (AWEPhotoAlbumPhoto *p in photos) {
                NSURL *u = [p.originPhotoURL bestURLtoDownload];
                if (u) dt_downloadURL(u, YES);
            }
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel handler:nil]];
    [dt_topVC() presentViewController:sheet animated:YES completion:nil];
}

// ─── Settings VC ─────────────────────────────────────────────────────────────
typedef struct { const char *key; const char *title; const char *detail; } DtSetting;

static DtSetting kDtFeed[] = {
    { "dt_hide_ads",            "Hide Ads",                  "Remove all ads from feed"         },
    { "dt_download_btn",        "Download Button",           "Show download button on videos"   },
    { "dt_progress_bar",        "Progress Bar",              "Seekable video progress bar"      },
    { "dt_auto_play",           "Auto-Advance",              "Auto play next video in feed"     },
    { "dt_stop_loop",           "Stop Looping",              "Don't repeat videos"              },
    { "dt_skip_recs",           "Skip Recommendations",      "Skip 'For You' recommendation cards" },
    { "dt_transparent_comments","Transparent Comments",      "Semi-transparent comment panel"   },
    { "dt_show_username",       "Show @Username",            "Show username instead of nickname"},
    { "dt_no_pull_refresh",     "Disable Pull-to-Refresh",   "Prevent accidental refresh"       },
    { "dt_no_sensitive",        "No Sensitive Blur",         "Disable blurred sensitive content"},
    { "dt_no_warnings",         "No Content Warnings",       "Remove warning overlays"          },
    { "dt_no_live",             "Hide LIVE in Feed",         "Remove live video entries"        },
    { "dt_upload_region",       "Upload Region Flag",        "Show country flag on videos"      },
};
static const int kDtFeedCount = 13;

static DtSetting kDtProfile[] = {
    { "dt_profile_save",  "Save Profile Photo",    "Long press avatar to save"    },
    { "dt_profile_copy",  "Copy Bio",              "Long press bio to copy text"  },
    { "dt_video_likes",   "Likes on Grid",         "Show like count on videos"    },
    { "dt_video_date",    "Upload Date on Grid",   "Show date on profile videos"  },
    { "dt_video_count",   "Video Count",           "Show total video count"       },
};
static const int kDtProfileCount = 5;

static DtSetting kDtSecurity[] = {
    { "dt_app_lock",       "App Lock",             "Face ID / Touch ID lock"      },
    { "dt_like_confirm",   "Confirm Like",         "Confirm before liking"        },
    { "dt_follow_confirm", "Confirm Follow",       "Confirm before following"     },
};
static const int kDtSecurityCount = 3;

static CGFloat kDtSpeeds[] = {0.5f, 0.75f, 1.0f, 1.5f, 2.0f, 3.0f};
static NSString * const kDtSpeedLabels[] = {@"0.5×", @"0.75×", @"1× (Normal)", @"1.5×", @"2×", @"3×"};

@interface FeaturesSettingsVC : UITableViewController
@end

@implementation FeaturesSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Features";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self action:@selector(close)];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 4; }

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    switch(s){ case 0: return @"Feed & UI"; case 1: return @"Playback Speed";
               case 2: return @"Profile";   case 3: return @"Security"; }
    return nil;
}
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    if (s == 3) return @"Tap speed to select. Changes apply immediately.";
    return nil;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    switch(s){ case 0: return kDtFeedCount; case 1: return 6;
               case 2: return kDtProfileCount; case 3: return kDtSecurityCount; }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (ip.section == 1) {
        cell.textLabel.text = kDtSpeedLabels[ip.row];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        CGFloat saved = FVAL(K_SPEED_VAL);
        if (saved < 0.1f) saved = 1.0f;
        cell.accessoryType = (fabsf(saved - kDtSpeeds[ip.row]) < 0.01f)
            ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        return cell;
    }

    DtSetting *arr = nil; int idx = (int)ip.row;
    switch(ip.section){
        case 0: arr = kDtFeed;     break;
        case 2: arr = kDtProfile;  break;
        case 3: arr = kDtSecurity; break;
    }
    if (!arr) return cell;

    cell.textLabel.text       = @(arr[idx].title);
    cell.detailTextLabel.text = @(arr[idx].detail);
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;

    UISwitch *sw = [UISwitch new];
    sw.on = FPREF(@(arr[idx].key));
    sw.tag = ip.section * 100 + ip.row;
    [sw addTarget:self action:@selector(toggled:)
        forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section != 1) return;
    [[NSUserDefaults standardUserDefaults] setFloat:kDtSpeeds[ip.row] forKey:K_SPEED_VAL];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:K_SPEED_EN];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [tv reloadSections:[NSIndexSet indexSetWithIndex:1]
        withRowAnimation:UITableViewRowAnimationNone];
}

- (void)toggled:(UISwitch *)sw {
    int section = (int)(sw.tag / 100);
    int row     = (int)(sw.tag % 100);
    DtSetting *arr = nil;
    switch(section){ case 0: arr=kDtFeed; break; case 2: arr=kDtProfile; break; case 3: arr=kDtSecurity; break; }
    if (!arr) return;
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@(arr[row].key)];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (section == 3 && row == 0 && !sw.on) _dt_lockShown = NO;
}

@end

UIViewController *doux_featuresSettingsVC(void) {
    return [FeaturesSettingsVC new];
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOOKS via method_exchangeImplementations
// ═══════════════════════════════════════════════════════════════════════════════

// ─── 1. AWEAwemeModel — hide ads, progress bar, no-live ──────────────────────
@interface NSObject (DtAweme)
- (id)dt_initWithDictionary:(id)d error:(id *)e;
- (id)dt_init;
- (BOOL)dt_progressBarDraggable;
- (BOOL)dt_progressBarVisible;
- (void)dt_live_callInitWithDictyCategoryMethod:(id)a;
+ (id)dt_liveStreamURLJSONTransformer;
+ (id)dt_relatedLiveJSONTransformer;
+ (id)dt_rawModelFromLiveRoomModel:(id)a;
+ (id)dt_aweLiveRoom_subModelPropertyKey;
@end
@implementation NSObject (DtAweme)
- (id)dt_initWithDictionary:(id)d error:(id *)e {
    id o = [self dt_initWithDictionary:d error:e];
    if (FPREF(K_HIDE_ADS) && [o isKindOfClass:NSClassFromString(@"AWEAwemeModel")]) {
        if ([(AWEAwemeModel *)o isAds]) return nil;
    }
    return o;
}
- (id)dt_init {
    id o = [self dt_init];
    if (FPREF(K_HIDE_ADS) && [o isKindOfClass:NSClassFromString(@"AWEAwemeModel")]) {
        if ([(AWEAwemeModel *)o isAds]) return nil;
    }
    return o;
}
- (BOOL)dt_progressBarDraggable { return FPREF(K_PROGRESS_BAR) ? YES : [self dt_progressBarDraggable]; }
- (BOOL)dt_progressBarVisible   { return FPREF(K_PROGRESS_BAR) ? YES : [self dt_progressBarVisible];   }
- (void)dt_live_callInitWithDictyCategoryMethod:(id)a {
    if (!FPREF(K_NO_LIVE)) [self dt_live_callInitWithDictyCategoryMethod:a];
}
+ (id)dt_liveStreamURLJSONTransformer   { return FPREF(K_NO_LIVE) ? nil : [self dt_liveStreamURLJSONTransformer];   }
+ (id)dt_relatedLiveJSONTransformer     { return FPREF(K_NO_LIVE) ? nil : [self dt_relatedLiveJSONTransformer];     }
+ (id)dt_rawModelFromLiveRoomModel:(id)a{ return FPREF(K_NO_LIVE) ? nil : [self dt_rawModelFromLiveRoomModel:a];    }
+ (id)dt_aweLiveRoom_subModelPropertyKey{ return FPREF(K_NO_LIVE) ? nil : [self dt_aweLiveRoom_subModelPropertyKey];}
@end

// ─── 2. TTKMediaSpeedControlService — persistent playback speed ───────────────
@interface NSObject (DtSpeed)
- (void)dt_setPlaybackRate:(CGFloat)rate;
@end
@implementation NSObject (DtSpeed)
- (void)dt_setPlaybackRate:(CGFloat)rate {
    CGFloat s = FVAL(K_SPEED_VAL);
    if (FPREF(K_SPEED_EN) && s > 0.1f)
        [self dt_setPlaybackRate:s];
    else
        [self dt_setPlaybackRate:rate];
}
@end

// ─── 3. AWEPlayVideoPlayerController — auto-play, stop loop, skip recs ────────
@interface NSObject (DtPlayer)
- (void)dt_playerWillLoopPlaying:(id)a;
- (BOOL)dt_loop;
- (void)dt_setLoop:(BOOL)v;
- (void)dt_containerDidFullyDisplayWithReason:(NSInteger)r;
@end
@implementation NSObject (DtPlayer)
- (void)dt_playerWillLoopPlaying:(id)a {
    if (FPREF(K_AUTO_PLAY)) {
        id container = [(AWEPlayVideoPlayerController *)self container];
        UIViewController *parent = [container parentViewController];
        if ([parent isKindOfClass:NSClassFromString(@"AWENewFeedTableViewController")]) {
            [(AWENewFeedTableViewController *)parent scrollToNextVideo];
            return;
        }
    }
    [self dt_playerWillLoopPlaying:a];
}
- (BOOL)dt_loop { return FPREF(K_STOP_LOOP) ? NO : [self dt_loop]; }
- (void)dt_setLoop:(BOOL)v { [self dt_setLoop:FPREF(K_STOP_LOOP) ? NO : v]; }
- (void)dt_containerDidFullyDisplayWithReason:(NSInteger)r {
    if (FPREF(K_SKIP_RECS)) {
        id container = [(AWEPlayVideoPlayerController *)self container];
        UIViewController *parent = [container parentViewController];
        if ([parent isKindOfClass:NSClassFromString(@"AWENewFeedTableViewController")]) {
            AWENewFeedTableViewController *feed = (AWENewFeedTableViewController *)parent;
            AWEAwemeModel *model = [feed currentAweme];
            if ([model isUserRecommendBigCard]) {
                [feed scrollToNextVideo];
                return;
            }
        }
    }
    [self dt_containerDidFullyDisplayWithReason:r];
}
@end

// ─── 4. AWEMaskInfoModel — no sensitive content blur ─────────────────────────
@interface NSObject (DtMask)
- (BOOL)dt_showMask;
- (void)dt_setShowMask:(BOOL)v;
@end
@implementation NSObject (DtMask)
- (BOOL)dt_showMask     { return FPREF(K_NO_SENSITIVE) ? NO : [self dt_showMask];         }
- (void)dt_setShowMask:(BOOL)v { [self dt_setShowMask:FPREF(K_NO_SENSITIVE) ? NO : v];    }
@end

// ─── 5. AWEPlayInteractionWarningElementView — remove warnings ────────────────
@interface NSObject (DtWarn)
- (id)dt_warningImage;
- (id)dt_warningLabel;
@end
@implementation NSObject (DtWarn)
- (id)dt_warningImage { return FPREF(K_NO_WARNINGS) ? nil : [self dt_warningImage]; }
- (id)dt_warningLabel { return FPREF(K_NO_WARNINGS) ? nil : [self dt_warningLabel]; }
@end

// ─── 6. TTKCommentPanelViewController — transparent comments ─────────────────
@interface NSObject (DtComment)
- (void)dt_comment_viewDidLoad;
@end
@implementation NSObject (DtComment)
- (void)dt_comment_viewDidLoad {
    [self dt_comment_viewDidLoad];
    if (FPREF(K_TRANSPARENT_C))
        ((UIViewController *)self).view.alpha = 0.90f;
}
@end

// ─── 7. AWENewFeedTableViewController — disable pull-to-refresh ───────────────
@interface NSObject (DtFeed)
- (BOOL)dt_disablePullToRefreshGestureRecognizer;
@end
@implementation NSObject (DtFeed)
- (BOOL)dt_disablePullToRefreshGestureRecognizer {
    return FPREF(K_NO_REFRESH) ? YES : [self dt_disablePullToRefreshGestureRecognizer];
}
@end

// ─── 8. TUXLabel — show @username instead of nickname ────────────────────────
@interface UILabel (DtUsername)
- (void)dt_setText:(NSString *)t;
@end
@implementation UILabel (DtUsername)
- (void)dt_setText:(NSString *)t {
    if (FPREF(K_SHOW_USERNAME) && t.length > 0) {
        UIView *sup2 = [self.superview superview];
        if ([sup2 isKindOfClass:NSClassFromString(@"AWEPlayInteractionAuthorUserNameButton")]) {
            AWEFeedCellViewController *vc = (AWEFeedCellViewController *)[sup2 yy_viewController];
            NSString *username = vc.model.author.socialName;
            if (username.length) { [self dt_setText:username]; return; }
        }
    }
    [self dt_setText:t];
}
@end

// ─── 9. AWEPlayInteractionAuthorView — upload region flag ─────────────────────
@interface NSObject (DtRegion)
- (void)dt_layoutSubviews_region;
@end
@implementation NSObject (DtRegion)
- (void)dt_layoutSubviews_region {
    [self dt_layoutSubviews_region];
    if (!FPREF(K_UPLOAD_REGION)) return;
    UIView *selfView = (UIView *)self;

    [[selfView viewWithTag:6661] removeFromSuperview];

    AWEFeedCellViewController *vc = (AWEFeedCellViewController *)[selfView yy_viewController];
    NSString *region = vc.model.region;
    if (!region.length) return;

    NSString *flag = dt_flagEmoji(region);
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 39, 20)];
    lbl.text = [NSString stringWithFormat:@"%@ •", flag];
    lbl.textColor = UIColor.whiteColor;
    lbl.font = [UIFont systemFontOfSize:14];
    lbl.tag = 6661;
    [lbl sizeToFit];

    for (UIView *sub in selfView.subviews) {
        if ([sub isKindOfClass:[UIStackView class]]) {
            CGRect f = sub.frame;
            f.origin.x = 42;
            sub.frame = f;
        }
    }
    [selfView addSubview:lbl];
}
@end

// ─── 10. AWEFeedVideoButton — like confirmation ───────────────────────────────
@interface NSObject (DtLike)
- (void)dt_like_touchUpInside;
@end
@implementation NSObject (DtLike)
- (void)dt_like_touchUpInside {
    if (FPREF(K_LIKE_CONFIRM)) {
        NSString *imgName = [(AWEFeedVideoButton *)self imageNameString];
        if ([imgName containsString:@"ic_like"]) {
            dt_confirm(@"Like this video?", ^{ [self dt_like_touchUpInside]; });
            return;
        }
    }
    [self dt_like_touchUpInside];
}
@end

// ─── 11. UIButton — follow confirmation ──────────────────────────────────────
@interface UIButton (DtFollow)
- (void)dt_follow_touchUpInside;
@end
@implementation UIButton (DtFollow)
- (void)dt_follow_touchUpInside {
    if (FPREF(K_FOLLOW_CONFIRM) &&
        [self.currentTitle isEqualToString:@"Follow"]) {
        dt_confirm(@"Follow this user?", ^{ [self dt_follow_touchUpInside]; });
    } else {
        [self dt_follow_touchUpInside];
    }
}
@end

// ─── 12. AWEProfileEditTextViewController — extended bio (300 chars) ──────────
@interface NSObject (DtBio)
- (NSInteger)dt_maxTextLength;
@end
@implementation NSObject (DtBio)
- (NSInteger)dt_maxTextLength { return 300; }
@end

// ─── 13. AWETextInputController — extended comments (500 chars) ───────────────
@interface NSObject (DtTextInput)
- (NSUInteger)dt_maxLength;
@end
@implementation NSObject (DtTextInput)
- (NSUInteger)dt_maxLength { return 500; }
@end

// ─── 14. AWEAwemeACLItem — remove watermark ──────────────────────────────────
@interface NSObject (DtWatermark)
- (void)dt_setWatermarkType:(NSUInteger)v;
- (NSUInteger)dt_watermarkType;
@end
@implementation NSObject (DtWatermark)
- (void)dt_setWatermarkType:(NSUInteger)v { [self dt_setWatermarkType:1]; }
- (NSUInteger)dt_watermarkType            { return 1; }
@end

// ─── 15. TTKProfileRootView — video count on profile ──────────────────────────
@interface NSObject (DtCount)
- (void)dt_layoutSubviews_count;
@end
@implementation NSObject (DtCount)
- (void)dt_layoutSubviews_count {
    [self dt_layoutSubviews_count];
    if (!FPREF(K_VIDEO_COUNT)) return;
    UIView *selfView = (UIView *)self;
    if ([selfView viewWithTag:6662]) return;

    TTKProfileOtherViewController *vc = (TTKProfileOtherViewController *)[selfView yy_viewController];
    NSNumber *cnt = vc.user.visibleVideosCount;
    if (!cnt) return;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 4, 200, 18)];
    lbl.text  = [NSString stringWithFormat:@"Videos: %@", cnt];
    lbl.font  = [UIFont systemFontOfSize:9];
    lbl.tag   = 6662;
    [selfView addSubview:lbl];
}
@end

// ─── 16. BDImageView — profile photo long press save ─────────────────────────
@interface UIImageView (DtSavePhoto)
- (void)dt_bdimage_layoutSubviews;
- (void)dt_bdHandleLongPress:(UILongPressGestureRecognizer *)g;
- (void)dt_bdImage:(UIImage *)img didFinishSavingWithError:(NSError *)e contextInfo:(void *)ctx;
@end
@implementation UIImageView (DtSavePhoto)
- (void)dt_bdimage_layoutSubviews {
    [self dt_bdimage_layoutSubviews];
    if (!FPREF(K_PROFILE_SAVE)) return;
    for (UIGestureRecognizer *g in self.gestureRecognizers)
        if ([g isKindOfClass:[UILongPressGestureRecognizer class]]) return;
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(dt_bdHandleLongPress:)];
    lp.minimumPressDuration = 0.4;
    [self addGestureRecognizer:lp];
    self.userInteractionEnabled = YES;
}
- (void)dt_bdHandleLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    UIImage *img = self.image;
    if (!img) return;
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"Save photo?"
        message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Save"
        style:UIAlertActionStyleDefault handler:^(id _) {
        UIImageWriteToSavedPhotosAlbum(img, self,
            @selector(dt_bdImage:didFinishSavingWithError:contextInfo:), nil);
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel handler:nil]];
    [dt_topVC() presentViewController:a animated:YES completion:nil];
}
- (void)dt_bdImage:(UIImage *)img didFinishSavingWithError:(NSError *)e contextInfo:(void *)ctx {
    dt_showAlert(@"DeTok", e ? @"Save failed" : @"Photo saved!");
}
@end

// ─── 17. TIKTOKProfileHeaderView — copy bio long press ───────────────────────
@interface UIView (DtCopyBio)
- (void)dt_profile_header_init_lp;
- (void)dt_profileHeaderLongPress:(UILongPressGestureRecognizer *)g;
@end
@implementation UIView (DtCopyBio)
- (void)dt_profile_header_init_lp {
    [self dt_profile_header_init_lp]; // calls original initWithFrame via swizzle
    if (FPREF(K_PROFILE_COPY)) {
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(dt_profileHeaderLongPress:)];
        lp.minimumPressDuration = 0.5;
        [self addGestureRecognizer:lp];
    }
}
- (void)dt_profileHeaderLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    // Find bio label via subview scan
    NSString *bio = nil;
    NSArray *queue = @[self];
    while (queue.count > 0) {
        UIView *v = queue.firstObject;
        queue = [queue subarrayWithRange:NSMakeRange(1, queue.count - 1)];
        if ([v isKindOfClass:[UILabel class]]) {
            NSString *txt = ((UILabel *)v).text;
            if (txt.length > 5) { bio = txt; break; }
        }
        queue = [queue arrayByAddingObjectsFromArray:v.subviews];
    }
    if (!bio) return;
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"Copy bio?"
        message:bio preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Copy"
        style:UIAlertActionStyleDefault handler:^(id _) {
        [UIPasteboard generalPasteboard].string = bio;
        dt_showAlert(@"DeTok", @"Bio copied!");
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel handler:nil]];
    [dt_topVC() presentViewController:a animated:YES completion:nil];
}
@end

// ─── 18. AWEUserWorkCollectionViewCell — likes + date on profile grid ─────────
@interface UICollectionViewCell (DtGrid)
- (void)dt_configWithModel:(id)m isMine:(BOOL)mine;
@end
@implementation UICollectionViewCell (DtGrid)
- (void)dt_configWithModel:(id)m isMine:(BOOL)mine {
    [self dt_configWithModel:m isMine:mine];
    if (![m isKindOfClass:NSClassFromString(@"AWEAwemeModel")]) return;
    if (!FPREF(K_VIDEO_LIKES) && !FPREF(K_VIDEO_DATE)) return;

    AWEAwemeModel *model = (AWEAwemeModel *)m;

    // Remove old labels
    for (UIView *v in [self.contentView subviews])
        if (v.tag == 1001 || v.tag == 1002) [v removeFromSuperview];

    if (FPREF(K_VIDEO_LIKES)) {
        NSInteger likes = [model.statistics.diggCount integerValue];
        UILabel *lbl = [UILabel new];
        lbl.text = [NSString stringWithFormat:@"♥ %@", dt_formatNumber(likes)];
        lbl.textColor = UIColor.whiteColor;
        lbl.font = [UIFont boldSystemFontOfSize:11];
        lbl.tag = 1001;
        lbl.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:lbl];
        [NSLayoutConstraint activateConstraints:@[
            [lbl.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
            [lbl.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:4],
        ]];
    }
    if (FPREF(K_VIDEO_DATE)) {
        NSTimeInterval ts = [model.createTime doubleValue];
        UILabel *lbl = [UILabel new];
        lbl.text = dt_formatDate(ts);
        lbl.textColor = UIColor.whiteColor;
        lbl.font = [UIFont systemFontOfSize:10];
        lbl.tag = 1002;
        lbl.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:lbl];
        [NSLayoutConstraint activateConstraints:@[
            [lbl.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
            [lbl.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:4],
        ]];
    }
}
@end

// ─── 19. AWEFeedViewTemplateCell — download button ────────────────────────────
@interface UIView (DtDownload)
- (void)dt_feed_configWithModel:(id)m;
- (void)dt_feed_configureWithModel:(id)m;
- (void)dt_addDownloadButton;
- (void)dt_downloadBtnTapped:(UIButton *)btn;
@end
@implementation UIView (DtDownload)
- (void)dt_feed_configWithModel:(id)m {
    [self dt_feed_configWithModel:m];
    if (FPREF(K_DOWNLOAD_BTN)) [self dt_addDownloadButton];
}
- (void)dt_feed_configureWithModel:(id)m {
    [self dt_feed_configureWithModel:m];
    if (FPREF(K_DOWNLOAD_BTN)) [self dt_addDownloadButton];
}
- (void)dt_addDownloadButton {
    if ([self viewWithTag:9988]) return;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.tag = 9988;
    [btn setImage:[UIImage systemImageNamed:@"arrow.down.circle.fill"]
        forState:UIControlStateNormal];
    btn.tintColor = UIColor.whiteColor;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:@selector(dt_downloadBtnTapped:)
        forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];
    [NSLayoutConstraint activateConstraints:@[
        [btn.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
        [btn.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
        [btn.widthAnchor constraintEqualToConstant:36],
        [btn.heightAnchor constraintEqualToConstant:36],
    ]];
}
- (void)dt_downloadBtnTapped:(UIButton *)btn {
    // Walk up to find AWEFeedCellViewController
    UIResponder *r = self;
    while (r) {
        r = r.nextResponder;
        if ([r isKindOfClass:NSClassFromString(@"AWEFeedCellViewController")]) break;
    }
    AWEFeedCellViewController *vc = (AWEFeedCellViewController *)r;
    if (!vc || !vc.model) return;
    dt_showDownloadSheet(vc.model);
}
@end

// ─── 20. AWELiveFeedEntranceView — hide live (swizzle switchStateWithTapped) ──
@interface NSObject (DtLiveView)
- (void)dt_switchStateWithTapped:(BOOL)tapped;
@end
@implementation NSObject (DtLiveView)
- (void)dt_switchStateWithTapped:(BOOL)tapped {
    if (!FPREF(K_NO_LIVE))
        [self dt_switchStateWithTapped:tapped];
}
@end

// ─── 21. AppDelegate — app lock on become active ─────────────────────────────
@interface NSObject (DtAppDelegate)
- (void)dt_applicationDidBecomeActive:(UIApplication *)app;
@end
@implementation NSObject (DtAppDelegate)
- (void)dt_applicationDidBecomeActive:(UIApplication *)app {
    [self dt_applicationDidBecomeActive:app];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ dt_showAppLock(); });
}
@end

// ═══════════════════════════════════════════════════════════════════════════════
// INSTALL ALL HOOKS
// ═══════════════════════════════════════════════════════════════════════════════
static void dt_installHooks(void) {
    // 1. AWEAwemeModel
    Class aweme = NSClassFromString(@"AWEAwemeModel");
    if (aweme) {
        dt_swizzle(aweme,
            @selector(initWithDictionary:error:),
            @selector(dt_initWithDictionary:error:));
        dt_swizzle(aweme, @selector(init),                @selector(dt_init));
        dt_swizzle(aweme, @selector(progressBarDraggable),@selector(dt_progressBarDraggable));
        dt_swizzle(aweme, @selector(progressBarVisible),  @selector(dt_progressBarVisible));
        dt_swizzle(aweme,
            @selector(live_callInitWithDictyCategoryMethod:),
            @selector(dt_live_callInitWithDictyCategoryMethod:));
        dt_swizzle_class(aweme,
            @selector(liveStreamURLJSONTransformer),
            @selector(dt_liveStreamURLJSONTransformer));
        dt_swizzle_class(aweme,
            @selector(relatedLiveJSONTransformer),
            @selector(dt_relatedLiveJSONTransformer));
        dt_swizzle_class(aweme,
            @selector(rawModelFromLiveRoomModel:),
            @selector(dt_rawModelFromLiveRoomModel:));
        dt_swizzle_class(aweme,
            @selector(aweLiveRoom_subModelPropertyKey),
            @selector(dt_aweLiveRoom_subModelPropertyKey));
    }

    // 2. Playback speed
    Class speedSvc = NSClassFromString(@"TTKMediaSpeedControlService");
    if (speedSvc)
        dt_swizzle(speedSvc, @selector(setPlaybackRate:), @selector(dt_setPlaybackRate:));

    // 3. Player controller
    Class player = NSClassFromString(@"AWEPlayVideoPlayerController");
    if (player) {
        dt_swizzle(player, @selector(playerWillLoopPlaying:), @selector(dt_playerWillLoopPlaying:));
        dt_swizzle(player, @selector(loop),    @selector(dt_loop));
        dt_swizzle(player, @selector(setLoop:),@selector(dt_setLoop:));
        dt_swizzle(player,
            @selector(containerDidFullyDisplayWithReason:),
            @selector(dt_containerDidFullyDisplayWithReason:));
    }

    // 4. Mask / sensitive
    Class mask = NSClassFromString(@"AWEMaskInfoModel");
    if (mask) {
        dt_swizzle(mask, @selector(showMask),     @selector(dt_showMask));
        dt_swizzle(mask, @selector(setShowMask:), @selector(dt_setShowMask:));
    }

    // 5. Warning overlay
    Class warn = NSClassFromString(@"AWEPlayInteractionWarningElementView");
    if (warn) {
        dt_swizzle(warn, @selector(warningImage), @selector(dt_warningImage));
        dt_swizzle(warn, @selector(warningLabel), @selector(dt_warningLabel));
    }

    // 6. Transparent comments
    Class commentVC = NSClassFromString(@"TTKCommentPanelViewController");
    if (commentVC)
        dt_swizzle(commentVC, @selector(viewDidLoad), @selector(dt_comment_viewDidLoad));

    // 7. Pull-to-refresh
    Class feedVC = NSClassFromString(@"AWENewFeedTableViewController");
    if (feedVC)
        dt_swizzle(feedVC,
            @selector(disablePullToRefreshGestureRecognizer),
            @selector(dt_disablePullToRefreshGestureRecognizer));

    // 8. Username label
    Class tuxLabel = NSClassFromString(@"TUXLabel");
    if (tuxLabel)
        dt_swizzle(tuxLabel, @selector(setText:), @selector(dt_setText:));

    // 9. Upload region flag
    Class authorView = NSClassFromString(@"AWEPlayInteractionAuthorView");
    if (authorView)
        dt_swizzle(authorView, @selector(layoutSubviews), @selector(dt_layoutSubviews_region));

    // 10. Like confirmation
    Class likeBtn = NSClassFromString(@"AWEFeedVideoButton");
    if (likeBtn)
        dt_swizzle(likeBtn, @selector(_onTouchUpInside), @selector(dt_like_touchUpInside));

    // 11. Follow confirmation
    dt_swizzle([UIButton class], @selector(_onTouchUpInside), @selector(dt_follow_touchUpInside));

    // 12. Extended bio
    Class bioVC = NSClassFromString(@"AWEProfileEditTextViewController");
    if (bioVC)
        dt_swizzle(bioVC, @selector(maxTextLength), @selector(dt_maxTextLength));

    // 13. Extended comments
    Class textInput = NSClassFromString(@"AWETextInputController");
    if (textInput)
        dt_swizzle(textInput, @selector(maxLength), @selector(dt_maxLength));

    // 14. Remove watermark
    Class aclItem = NSClassFromString(@"AWEAwemeACLItem");
    if (aclItem) {
        dt_swizzle(aclItem, @selector(setWatermarkType:), @selector(dt_setWatermarkType:));
        dt_swizzle(aclItem, @selector(watermarkType),     @selector(dt_watermarkType));
    }

    // 15. Video count on profile
    Class profileRoot = NSClassFromString(@"TTKProfileRootView");
    if (profileRoot)
        dt_swizzle(profileRoot, @selector(layoutSubviews), @selector(dt_layoutSubviews_count));

    // 16. Profile photo save
    Class bdImage = NSClassFromString(@"BDImageView");
    if (bdImage)
        dt_swizzle(bdImage, @selector(layoutSubviews), @selector(dt_bdimage_layoutSubviews));

    // 17. Profile bio copy
    Class profileHeader = NSClassFromString(@"TIKTOKProfileHeaderView");
    if (profileHeader) {
        // Swizzle viewDidLoad to add long press
        Method orig = class_getInstanceMethod(profileHeader, @selector(viewDidLoad));
        if (!orig) {
            // Try layoutSubviews
            orig = class_getInstanceMethod(profileHeader, @selector(layoutSubviews));
            if (orig) dt_swizzle(profileHeader, @selector(layoutSubviews), @selector(dt_profile_header_init_lp));
        } else {
            dt_swizzle(profileHeader, @selector(viewDidLoad), @selector(dt_profile_header_init_lp));
        }
    }

    // 18. Likes + date on profile grid
    Class gridCell = NSClassFromString(@"AWEUserWorkCollectionViewCell");
    if (gridCell)
        dt_swizzle(gridCell,
            @selector(configWithModel:isMine:),
            @selector(dt_configWithModel:isMine:));

    // 19. Download button on feed
    Class feedCell = NSClassFromString(@"AWEFeedViewTemplateCell");
    if (feedCell) {
        dt_swizzle(feedCell, @selector(configWithModel:),    @selector(dt_feed_configWithModel:));
        dt_swizzle(feedCell, @selector(configureWithModel:), @selector(dt_feed_configureWithModel:));
    }

    // 20. Hide live entrance
    Class liveView = NSClassFromString(@"AWELiveFeedEntranceView");
    if (liveView)
        dt_swizzle(liveView, @selector(switchStateWithTapped:), @selector(dt_switchStateWithTapped:));

    // 21. App Lock
    Class appDel = NSClassFromString(@"AppDelegate") ?: NSClassFromString(@"TikTokAppDelegate");
    if (appDel)
        dt_swizzle(appDel,
            @selector(applicationDidBecomeActive:),
            @selector(dt_applicationDidBecomeActive:));
}

// ─── Entry point ──────────────────────────────────────────────────────────────
__attribute__((constructor))
static void features_init(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        dt_installHooks();
    });
}
