#import "TikTokHeaders.h"
#import "common.h"

// Returns YES if this URL should be blocked based on active ghost settings
static BOOL ghostShouldBlockURL(NSString *url) {
    if (!url || url.length == 0) return NO;

    if ([DouXManager ghostReadReceiptEnabled]) {
        if ([url containsString:@"/im/ack"]        ||
            [url containsString:@"msg_read"]        ||
            [url containsString:@"mark_read"]       ||
            [url containsString:@"/im/read"]        ||
            [url containsString:@"read_receipt"]) {
            return YES;
        }
    }

    if ([DouXManager ghostProfileViewEnabled]) {
        if ([url containsString:@"profile/view"]   ||
            [url containsString:@"profile_view"]   ||
            [url containsString:@"/user/browse"]   ||
            [url containsString:@"visit_profile"]  ||
            [url containsString:@"profile/other"]) {
            return YES;
        }
    }

    if ([DouXManager ghostOnlineStatusEnabled]) {
        if ([url containsString:@"im/presence"]    ||
            [url containsString:@"/im/login"]      ||
            [url containsString:@"online_status"]  ||
            [url containsString:@"user/status"]) {
            return YES;
        }
    }

    if ([DouXManager ghostTypingEnabled]) {
        if ([url containsString:@"im/typing"]      ||
            [url containsString:@"typing_status"]) {
            return YES;
        }
    }

    return NO;
}

// ─────────────────────────────────────────────
// READ RECEIPTS — block marking DMs as read
// ─────────────────────────────────────────────

%hook AWEIMConversationService
- (void)markConversationRead:(id)conversation {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)markMessagesRead:(id)messages inConversation:(id)conversation {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)markAllConversationsRead {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
%end

%hook IESIMService
- (void)ackMessages:(id)arg1 {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)markReadForConversation:(id)arg1 {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
- (void)sendReadReceiptForMessage:(id)arg1 {
    if (![DouXManager ghostReadReceiptEnabled]) { %orig; }
}
%end

// ─────────────────────────────────────────────
// PROFILE VIEW GHOST — invisible profile visits
// ─────────────────────────────────────────────

%hook AWEProfileViewService
- (void)recordProfileView:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
- (void)reportProfileView:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
- (void)sendProfileViewEvent:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
%end

%hook TTKProfilePageTrackHelper
- (void)trackEnterOtherProfile:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
- (void)sendVisitProfileEvent:(id)arg1 {
    if (![DouXManager ghostProfileViewEnabled]) { %orig; }
}
%end

%hook AWEUserBrowseService
- (void)reportBrowseUser:(id)arg1 {
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
        %orig(0); // 0 = offline
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
// TYPING INDICATOR — don't show "typing..."
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

%hook AWEIMInputBarViewModel
- (void)textDidChange:(id)arg1 {
    %orig;
    // typing event is normally triggered here — suppressed by AWEIMTypingService hook above
}
%end

// ─────────────────────────────────────────────
// NETWORK FALLBACK — catch anything that slipped
// through the class-level hooks above
// ─────────────────────────────────────────────

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (ghostShouldBlockURL(request.URL.absoluteString)) {
        // Wrap completion to return a fake 200 OK so TikTok doesn't retry
        NSURLRequest *capturedRequest = request;
        NSURLSessionDataTask *task = %orig(request, ^(NSData *d, NSURLResponse *r, NSError *e) {
            if (completionHandler) {
                NSHTTPURLResponse *fakeResp = [[NSHTTPURLResponse alloc]
                    initWithURL:capturedRequest.URL
                    statusCode:200
                    HTTPVersion:@"HTTP/1.1"
                    headerFields:@{@"Content-Type": @"application/json"}];
                NSData *fakeBody = [@"{\"status_code\":0,\"status_msg\":\"\"}"
                    dataUsingEncoding:NSUTF8StringEncoding];
                completionHandler(fakeBody, fakeResp, nil);
            }
        });
        [task cancel];
        return task;
    }
    return %orig;
}
%end
