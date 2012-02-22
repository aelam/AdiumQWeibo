//
//  QTweetHelper.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-18.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AdiumQWeiboEngine+Helper.h"
#import "RegexKitLite.h"

@interface AdiumQWeiboEngine (Private)

+ (void)_attributeTopicsForAttributedString:(NSMutableAttributedString *)halfAttributedTweet;
+ (void)_attributeEmotionsForAttributedString:(NSMutableAttributedString *)halfAttributedTweet;
+ (void)_attributeUsernamesForAttributedString:(NSMutableAttributedString *)halfAttributedTweet replacingNicknames:(NSDictionary *)pairs;

@end

@implementation AdiumQWeiboEngine (Helper)

/*!
 * @brief Returns the link URL for a specific type of link
 */
+ (NSString *)addressForLinkType:(AIQWeiboLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context
{
	NSString *address = nil;
	
	if (linkType == AIQWeiboLinkStatus) {
		address = [NSString stringWithFormat:@"http://t.qq.com/%@/status/%@", userID, statusID];
	} else if (linkType == AIQWeiboLinkFriends) {
		address = [NSString stringWithFormat:@"http://t.qq.com/%@/friends", userID];
	} else if (linkType == AIQWeiboLinkFollowings) {
		address = [NSString stringWithFormat:@"http://t.qq.com/%@/following", userID];        
	} else if (linkType == AIQWeiboLinkFollowers) {
		address = [NSString stringWithFormat:@"http://t.qq.com/%@/follower", userID]; 
	} else if (linkType == AIQWeiboLinkTweetCount) {
		address = [NSString stringWithFormat:@"http://t.qq.com/%@/mine", userID];
	} else if (linkType == AIQWeiboLinkUserPage) {
		address = [NSString stringWithFormat:@"http://t.qq.com/%@", userID]; 
	} else if (linkType == AIQWeiboLinkSearchHash) {
		address = [NSString stringWithFormat:@"http://t.qq.com/k/%@", context];
    } else if (linkType == AIQWeiboLinkReply) {
//		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=reply&status=%@", self.internalObjectID, userID, statusID];
        address = @"http://reply.com";
	} else if (linkType == AIQWeiboLinkRetweet) {
//		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=retweet&status=%@", self.internalObjectID, userID, statusID];
        address = @"http://retweet.com";
	} else if (linkType == AIQWeiboLinkFavorite) {
//		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=favorite&status=%@", self.internalObjectID, userID, statusID];
        address = @"http://favorite.com";
	} else if (linkType == AIQWeiboLinkDestroyStatus) {
//		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=destroy&status=%@&message=%@", self.internalObjectID, userID, statusID, context];
        address = @"http://delete.com";
	} else if (linkType == AIQWeiboLinkDestroyDM) {
//		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=destroy&dm=%@&message=%@", self.internalObjectID, userID, statusID, context];		
        address = @"http://AIQWeiboLinkDestroyDM";
	} else if (linkType == AIQWeiboLinkQuote) {
//		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=quote&message=%@", self.internalObjectID, userID, context];
        address = @"http://AIQWeiboLinkQuote";
	}
	
	return address;
}

+ (NSAttributedString *)attributedUserWithName:(NSString *)name nick:(NSString *)nick {
    if (nick == nil || nick.length == 0) {
        nick = name;
    } 
    if (name == nil || name.length == 0) {
        return nil;
    }
    NSDictionary *linkAttr = [[[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSCursor pointingHandCursor], NSCursorAttributeName,
                              [NSColor blueColor], NSForegroundColorAttributeName,
                              [NSString stringWithFormat:@"http://t.qq.com/%@",name],NSLinkAttributeName,
                              nil] autorelease];
    NSMutableAttributedString *attributedUser = [[NSMutableAttributedString alloc] initWithString:@"@"];
    NSAttributedString *realUser = [[NSAttributedString alloc] initWithString:nick attributes:linkAttr];
    [attributedUser appendAttributedString:realUser];
    [realUser release];
    return [attributedUser autorelease];
}

+ (NSAttributedString *)attributedTweetForPlainText:(NSString *)tweet replacingNicknames:(NSDictionary *)nicknamePairs {
    return [self attributedTweetForPlainText:tweet replacingNicknames:nicknamePairs processEmotion:YES];
}

+ (NSAttributedString *)attributedTweetForPlainText:(NSString *)tweet replacingNicknames:(NSDictionary *)nicknamePairs processEmotion:(BOOL)needProcess{
    if (tweet) {
        NSMutableAttributedString *halfAttributedTweet = [[NSMutableAttributedString alloc] initWithString:tweet];
        [self _attributeUsernamesForAttributedString:halfAttributedTweet replacingNicknames:nicknamePairs];
        if (needProcess) {
            [self _attributeEmotionsForAttributedString:halfAttributedTweet];            
        }
        [self _attributeTopicsForAttributedString:halfAttributedTweet];
        return [halfAttributedTweet autorelease];
    } else {
        return nil;
    }
}

+ (NSArray *)attributedTweetsFromTweetDictionary:(NSDictionary *)json{
    return [self attributedTweetsFromTweetDictionary:json processEmotion:YES];
}


+ (NSArray *)attributedTweetsFromTweetDictionary:(NSDictionary *)json processEmotion:(BOOL)needProcess{
    NSMutableArray *attributedTweets = [NSMutableArray array];
    
    NSDictionary *nicknamePairs = [json valueForKeyPath:@"data.user"];
    NSArray *statuses = [json valueForKeyPath:@"data.info"];                    
    
    for (NSDictionary *status in statuses) {
        NSString *plainTweet = [status objectForKey:@"origtext"];
        NSAttributedString *halfAttributedTweet = [self attributedTweetForPlainText:plainTweet replacingNicknames:nicknamePairs processEmotion:needProcess];
        [attributedTweets addObject:halfAttributedTweet];
    }
    return attributedTweets;
}

+ (void)_attributeTopicsForAttributedString:(NSMutableAttributedString *)halfAttributedTweet {
    static NSString *topicsCharacters = nil;
    
    if (topicsCharacters == nil) {
        topicsCharacters = [@"#([^\\#|.]+)#" retain];
    }
    
    [[halfAttributedTweet string] enumerateStringsMatchedByRegex:topicsCharacters usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        for (int i = 0; i < captureCount; i++) {
            if( capturedRanges[i].location != NSNotFound) {
                NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [NSCursor pointingHandCursor], NSCursorAttributeName,
                                          [NSColor blueColor], NSForegroundColorAttributeName,
                                          [NSString stringWithFormat:@"http://t.qq.com/k/%@",capturedStrings[i]],NSLinkAttributeName,
                                          nil];
                
                [halfAttributedTweet addAttributes:linkAttr range:capturedRanges[i]];
                [linkAttr release];
            }
        }
    }];
}


+ (void)_attributeUsernamesForAttributedString:(NSMutableAttributedString *)halfAttributedTweet replacingNicknames:(NSDictionary *)pairs{
    static NSString *usernameCharacters = nil;
    
    
    if (usernameCharacters == nil) {
        usernameCharacters = [@"(?<=@)[a-zA-Z0-9\\-_]+" retain];
    }
    
    __block NSUInteger replaceOffset = 0;
    
    [[halfAttributedTweet string] enumerateStringsMatchedByRegex:usernameCharacters usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        for (int i = 0; i < captureCount; i++) {
            if( capturedRanges[i].location != NSNotFound) {
                
                NSString *name = capturedStrings[i];
                NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [NSCursor pointingHandCursor], NSCursorAttributeName,
                                          [NSColor blueColor], NSForegroundColorAttributeName,
                                          [NSString stringWithFormat:@"http://t.qq.com/%@",name],NSLinkAttributeName,
                                          nil];
                NSString *nickname = [pairs objectForKey:name]?[pairs objectForKey:name]:name;
                NSAttributedString *nickAttributedString = [[[NSAttributedString alloc] initWithString:nickname attributes:linkAttr] autorelease];
                [halfAttributedTweet replaceCharactersInRange:NSMakeRange(capturedRanges[i].location + replaceOffset, capturedRanges[i].length) withAttributedString:nickAttributedString];
                [linkAttr release];                
                replaceOffset += nickAttributedString.length - capturedStrings[i].length;
                
            }
        }        
    }];    
}

+ (void)_attributeGroupsForAttributedString:(NSMutableAttributedString *)halfAttributedTweet replacingNicknames:(NSDictionary *)pairs{
    static NSString *usernameCharacters = nil;

    if (usernameCharacters == nil) {
        usernameCharacters = [@"(?<=@)*[a-zA-Z0-9\\-_]+" retain];
    }
    
    __block NSUInteger replaceOffset = 0;

    [[halfAttributedTweet string] enumerateStringsMatchedByRegex:usernameCharacters usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        for (int i = 0; i < captureCount; i++) {
            if( capturedRanges[i].location != NSNotFound) {
                        
                NSString *name = capturedStrings[i];
                NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [NSCursor pointingHandCursor], NSCursorAttributeName,
                                          [NSColor blueColor], NSForegroundColorAttributeName,
                                          [NSString stringWithFormat:@"http://t.qq.com/%@",name],NSLinkAttributeName,
                                          nil];
                NSString *nickname = [pairs objectForKey:name]?[pairs objectForKey:name]:name;
                NSAttributedString *nickAttributedString = [[[NSAttributedString alloc] initWithString:nickname attributes:linkAttr] autorelease];
                [halfAttributedTweet replaceCharactersInRange:NSMakeRange(capturedRanges[i].location + replaceOffset, capturedRanges[i].length) withAttributedString:nickAttributedString];
                [linkAttr release];                
                replaceOffset += nickAttributedString.length - capturedStrings[i].length;

            }
        }        
    }];    
}


+ (void)_attributeEmotionsForAttributedString:(NSMutableAttributedString *)halfAttributedTweet {
    
    NSBundle *bundle = [NSBundle bundleForClass:[AdiumQWeiboEngine class]];
    NSString *facePath = [bundle pathForResource:@"face" ofType:@"plist"];
    NSDictionary *facePairs = [NSDictionary dictionaryWithContentsOfFile:facePath];
    
    NSString *temp1 = [[facePairs allKeys] componentsJoinedByString:@"|/"];    
    NSString *regex = [NSString stringWithFormat:@"/%@",temp1];
    
    __block NSUInteger replaceOffset = 0;
    [[halfAttributedTweet string] enumerateStringsMatchedByRegex:regex usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        for (int i = 0; i < captureCount; i++) {
            NSString *temp = [capturedStrings[i] stringByReplacingOccurrencesOfString:@"/" withString:@""];
            NSString *realFaceName = [facePairs objectForKey:temp];
            
            NSAttributedString *imageString;
            NSTextAttachment *ta = [[[NSTextAttachment alloc] init] autorelease];
            NSTextAttachmentCell *cell = [[[NSTextAttachmentCell alloc] init] autorelease];
            NSImage *image = nil;
            
            
            image = [bundle imageForResource:[NSString stringWithFormat:@"%@.gif",realFaceName]];
            [cell setImage:image];
            [ta setAttachmentCell:cell];            
            imageString  = [NSAttributedString attributedStringWithAttachment:ta];
            [halfAttributedTweet replaceCharactersInRange:NSMakeRange(capturedRanges[i].location + replaceOffset, capturedRanges[i].length) withAttributedString:imageString];
            replaceOffset += imageString.length - capturedStrings[i].length;
        }
    }];
}


/**
 *   (RT, ¶, @, ☆, #)
 */
// 转播
#define RT_SIGN         @"RT"
// 引用
#define PILCROW_SIGN    @"\u00B6"
#define AT              @"@"
#define FAVORITE_SIGN   @"\u2606"
#define OPEN_TWEET      @"#"

+ (NSAttributedString *)suffixActionAttributedStringWithTweetID:(NSString *)tweetID myID:(NSString *)name{
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:@"("] autorelease];
    
    NSString *retweetAddress = [self addressForLinkType:AIQWeiboLinkRetweet userID:name statusID:tweetID context:nil];
    
    NSAttributedString *retweet = [NSAttributedString attributedStringWithLinkLabel:RT_SIGN linkDestination:retweetAddress];
    
    [attributedString appendAttributedString:retweet];

    [attributedString appendString:@") " withAttributes:nil];
    
    return attributedString;
}



@end
