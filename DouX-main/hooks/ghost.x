#import "TikTokHeaders.h"
#import "common.h"

// Real API endpoints extracted from MusicallyCore binary
static BOOL ghostShouldBlockURL(NSString *url) {
    if (!url || url.length == 0) return NO;

    if ([DouXManager ghostReadReceiptEnabled]) {
        if ([url containsString:@"/im/ack"]              ||
            [url containsString:@"mark_read"]             ||
            [url containsString:@"markRead"]              ||
            [url containsString:@"clear_unread"]          ||
            [url containsString:@"clear_unread_count"]    ||
            [url containsString:@"bulletin/clear"]) {
            return YES;
        }
    }

    if ([DouXManager ghostProfileViewEnabled]) {
        // Real endpoints from binary: /tiktok/user/profile/view_record/add/v1
        if ([url containsString:@"profile/view_record"]  ||
            [url containsString:@"profile/view"]         ||
            [url containsString:@"profileviewscontrol"]  ||
            [url containsString:@"profile_view"]) {
            return YES;
        }
    }

    if ([DouXManager ghostOnlineStatusEnabled]) {
        if ([url containsString:@"im/presence"]          ||
            [url containsString:@"im/status"]            ||
            [url containsString:@"online_status"]) {
            return YES;
        }
    }

    if ([DouXManager ghostTypingEnabled]) {
        // Real endpoint from binary: /tiktok/v2/im/typing_recommendation
        if ([url containsString:@"im/typing"]            ||
            [url containsString:@"typing_recommendation"]) {
            return YES;
        }
    }

    return NO;
}

// ─────────────────────────────────────────────
// READ RECEIPTS
// Real class: TIMConversationManager (TTIMSDK)
// ─────────────────────────────────────────────

%hook TIMConversationManager
- (void)markReadForConversation:(id)conversation {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)markReadWithConversationId:(id)convId {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)markAllConversationsRead {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
%end

// Auto-retry handler that resends read receipts
%hook TIMAutoRetryMarkReadHandler
- (void)handleAutoRetry:(id)arg1 {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)retryMarkRead:(id)arg1 {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
%end

// Notice mark-read manager
%hook TTKNoticeContentMarkReadManager
- (void)markContentRead:(id)arg1 {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)markAllRead {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
%end

// ─────────────────────────────────────────────
// PROFILE VIEW GHOST
// Real class: TTKProfileViewsVisitor (TTIMSDK)
// Real API:   /tiktok/user/profile/view_record/add/v1
// ─────────────────────────────────────────────

%hook TTKProfileViewsVisitor
- (void)visitProfile:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
- (void)sendVisitEvent:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
- (void)uploadVisitRecord:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
%end

%hook TTKProfileViewsManager
- (void)addProfileView:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
- (void)uploadPendingViews {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
%end

// ─────────────────────────────────────────────
// ONLINE STATUS — appear offline
// ─────────────────────────────────────────────

%hook AWEIMPresenceService
- (void)updatePresence:(id)arg1 {
    if (![DouXManager ghostOnlineStatusEnabled]) { %orig; }
}
- (void)setOnlineStatus:(NSInteger)status {
    if ([DouXManager ghostOnlineStatusEnabled]) {
        %orig(0);
    } else {
        %orig;
    }
}
%end

%hook AWEIMUserOnlineStateService
- (void)updateUserOnlineState:(id)arg1 {
    if (![DouXManager ghostOnlineStatusEnabled]) { %orig; }
}
- (void)setActiveStatus:(BOOL)active {
    if ([DouXManager ghostOnlineStatusEnabled]) {
        %orig(NO);
    } else {
        %orig;
    }
}
%end

// ─────────────────────────────────────────────
// TYPING INDICATOR
// Real API: /tiktok/v2/im/typing_recommendation
// ─────────────────────────────────────────────

%hook AWEIMTypingService
- (void)startTypingInConversation:(id)arg1 {
    if (![DouXManager ghostTypingEnabled]) { %orig; }
}
- (void)stopTypingInConversation:(id)arg1 {
    if (![DouXManager ghostTypingEnabled]) { %orig; }
}
- (void)sendTypingStatus:(BOOL)isTyping toConversation:(id)conv {
    if (![DouXManager ghostTypingEnabled]) { %orig; }
}
%end

// ─────────────────────────────────────────────
// NETWORK FALLBACK — blocks real API endpoints
// found in MusicallyCore binary
// ─────────────────────────────────────────────

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (ghostShouldBlockURL(request.URL.absoluteString)) {
        NSURL *blockedURL = request.URL;
        void (^fakeHandler)(NSData *, NSURLResponse *, NSError *) =
            ^(NSData *d, NSURLResponse *r, NSError *e) {
                if (completionHandler) {
                    NSHTTPURLResponse *fakeResp = [[NSHTTPURLResponse alloc]
                        initWithURL:blockedURL statusCode:200
                        HTTPVersion:@"HTTP/1.1"
                        headerFields:@{@"Content-Type": @"application/json"}];
                    completionHandler(
                        [@"{\"status_code\":0}" dataUsingEncoding:NSUTF8StringEncoding],
                        fakeResp, nil);
                }
            };
        NSURLSessionDataTask *task = %orig(request, fakeHandler);
        [task cancel];
        return task;
    }
    return %orig;
}
%end
