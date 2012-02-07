//
//  NSString+TweetContent.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 12-2-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//



@interface NSString (TweetContent)

+ (NSArray *)scanStringForLinks:(NSString *)string;

+ (NSArray *)scanStringForUsernames:(NSString *)string;

+ (NSArray *)scanStringForHashtags:(NSString *)string;

@end
