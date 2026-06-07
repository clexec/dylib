#import "TikTokHeaders.h"
#import "common.h"

// ── Region Bypass: locale / language spoofing ─────────────────────────────────
// These hooks complement the CTCarrier/TIKTOKRegionManager hooks below.
// NSLocale and NSBundle language affect how TikTok determines the client region.

static NSDictionary *langForCode() {
    return @{
        @"US": @"en", @"GB": @"en", @"AU": @"en", @"CA": @"en",
        @"JP": @"ja", @"KR": @"ko", @"TW": @"zh-Hant", @"HK": @"zh-Hant", @"MO": @"zh-Hant",
        @"DE": @"de", @"FR": @"fr", @"IT": @"it", @"FI": @"fi", @"DK": @"da", @"NO": @"no",
        @"RO": @"ro", @"RU": @"ru", @"TR": @"tr",
        @"SA": @"ar", @"AE": @"ar", @"EG": @"ar", @"KW": @"ar", @"LB": @"ar", @"SD": @"ar", @"DZ": @"ar",
        @"PH": @"fil", @"ID": @"id", @"MY": @"ms", @"TH": @"th", @"VN": @"vi",
        @"LA": @"lo", @"SG": @"en", @"PK": @"ur", @"BR": @"pt", @"MX": @"es",
        @"AR": @"es", @"PA": @"es", @"AI": @"en", @"IN": @"hi",
    };
}

%hook NSLocale
+ (NSLocale *)currentLocale {
    if ([DouXManager regionChangingEnabled] && [DouXManager selectedRegion]) {
        NSDictionary *region = [DouXManager selectedRegion];
        NSString *code = region[@"code"];
        NSString *lang = langForCode()[code] ?: @"en";
        NSString *localeID = [NSString stringWithFormat:@"%@_%@", lang, code];
        return [NSLocale localeWithLocaleIdentifier:localeID];
    }
    return %orig;
}
+ (NSLocale *)autoupdatingCurrentLocale {
    if ([DouXManager regionChangingEnabled] && [DouXManager selectedRegion]) {
        NSDictionary *region = [DouXManager selectedRegion];
        NSString *code = region[@"code"];
        NSString *lang = langForCode()[code] ?: @"en";
        NSString *localeID = [NSString stringWithFormat:@"%@_%@", lang, code];
        return [NSLocale localeWithLocaleIdentifier:localeID];
    }
    return %orig;
}
+ (NSArray<NSString *> *)preferredLanguages {
    if ([DouXManager regionChangingEnabled] && [DouXManager selectedRegion]) {
        NSDictionary *region = [DouXManager selectedRegion];
        NSString *code = [region[@"code"] lowercaseString];
        NSString *lang = langForCode()[[code uppercaseString]] ?: @"en";
        return @[
            [NSString stringWithFormat:@"%@-%@", lang, [code uppercaseString]],
            lang,
            @"en-US",
            @"en",
        ];
    }
    return %orig;
}
%end
// ─────────────────────────────────────────────────────────────────────────────

%hook SparkViewController // alwaysOpenSafari
- (void)viewWillAppear:(BOOL)animated {
    if (![DouXManager alwaysOpenSafari]) {
        return %orig;
    }
    
    // NSURL *url = self.originURL;
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.originURL resolvingAgainstBaseURL:NO];
    NSString *searchParameter = @"url";
    NSString *searchValue = nil;
    
    for (NSURLQueryItem *queryItem in components.queryItems) {
        if ([queryItem.name isEqualToString:searchParameter]) {
            searchValue = queryItem.value;
            break;
        }
    }
    
    // In-app browser is used for two-factor authentication with security key,
    // login will not complete successfully if it's redirected to Safari
    // if ([urlStr containsString:@"twitter.com/account/"] || [urlStr containsString:@"twitter.com/i/flow/"]) {
    //     return %orig;
    // }

    if (searchValue) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:searchValue] options:@{} completionHandler:nil];
        [self didTapCloseButton];
    } else {
        return %orig;
    }
}
%end

%hook CTCarrier // changes country 
- (NSString *)mobileCountryCode {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"mcc"];
        }
        return %orig;
    }
    return %orig;
}

- (void)setIsoCountryCode:(NSString *)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}

- (NSString *)isoCountryCode {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}

- (NSString *)mobileNetworkCode {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"mnc"];
        }
        return %orig;
    }
    return %orig;
}
%end
%hook TTKStoreRegionService
- (id)storeRegion {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (id)getStoreRegion {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (void)setStoreRegion:(id)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig([selectedRegion[@"code"] lowercaseString]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end
%hook TIKTOKRegionManager
+ (NSString *)systemRegion {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)region {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)mccmnc {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [NSString stringWithFormat:@"%@%@", selectedRegion[@"mcc"], selectedRegion[@"mnc"]];
        }
        return %orig;
    }
    return %orig;
}
+ (id)storeRegion {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)currentRegionV2 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)localRegion {
        if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}

%end

%hook TTKPassportAppStoreRegionModel
- (id)storeRegion {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (void)setStoreRegion:(id)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig([selectedRegion[@"code"] lowercaseString]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
- (void)setLocalizedCountryName:(id)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig(selectedRegion[@"name"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
- (id)localizedCountryName {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"name"];
        }
        return %orig;
    }
    return %orig;
}
%end

%hook ATSRegionCacheManager
- (id)getRegion {
 if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (id)storeRegionFromCache {
 if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (id)storeRegionFromTTNetNotification:(id)arg1 {
 if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (void)setRegion:(id)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig([selectedRegion[@"code"] lowercaseString]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
- (id)region {
 if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
%end

%hook TTKStoreRegionModel
- (id)storeRegion {
 if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
- (void)setStoreRegion:(id)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end

%hook TTInstallIDManager
- (id)currentAppRegion {
 if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
- (void)setCurrentAppRegion:(id)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end

%hook BDInstallGlobalConfig
- (id)currentAppRegion {
 if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
- (void)setCurrentAppRegion:(id)arg1 {
    if ([DouXManager regionChangingEnabled]) {
        if ([DouXManager selectedRegion]) {
            NSDictionary *selectedRegion = [DouXManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end