//
//  NSString+TweetContent.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 12-2-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NSString+TweetContent.h"
#import "RegexKitLite.h"

@implementation NSString (TweetContent)

+ (NSArray *)scanStringForLinks:(NSString *)string {
    return [string componentsMatchedByRegex:@"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))"];
}

+ (NSArray *)scanStringForUsernames:(NSString *)string {
    return [string componentsMatchedByRegex:@"@{1}([-A-Za-z0-9_]{2,})"];
}

+ (NSArray *)scanStringForHashtags:(NSString *)string {
//    return [string componentsMatchedByRegex:@"[\\s]{1,}#{1}([^\\s]{2,})"];
    return [string componentsMatchedByRegex:@"#([^\\#|.]+)#"];
}


@end
