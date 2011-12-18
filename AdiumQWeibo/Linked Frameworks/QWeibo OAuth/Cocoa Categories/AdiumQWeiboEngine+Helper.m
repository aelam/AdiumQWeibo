//
//  QTweetHelper.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-18.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AdiumQWeiboEngine+Helper.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

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


+ (NSAttributedString *)attributedTweetFromTweetDictionary:(NSDictionary *)json {
    
    static NSCharacterSet *usernameCharacters = nil;
	static NSCharacterSet *hashCharacters = nil;
	
	if (!usernameCharacters) {
		usernameCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"] retain];
	}
	
	if (!hashCharacters) {
		NSMutableCharacterSet	*disallowedCharacters = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
//		[disallowedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
		[disallowedCharacters removeCharactersInString:@"_"];
		
		hashCharacters = [[disallowedCharacters invertedSet] retain];
		
		[disallowedCharacters release];
	}

    NSInteger type = [[json objectForKey:@"type"] intValue];
    NSString *originText = [json objectForKey:@"origtext"];
    NSAttributedString *string = [[[NSAttributedString alloc] initWithString:[originText stringByAppendingString:@"\n"]] autorelease];
    
    // hyperlink topic
    NSAttributedString *originText1 = [self linkifiedStringFromAttributedString:string forPrefixCharacter:@"#" forLinkType:AIQWeiboLinkSearchHash validCharacterSet:hashCharacters];
    // hyperlink username
    NSAttributedString *originText2 = [self linkifiedStringFromAttributedString:originText1 forPrefixCharacter:@"@" forLinkType:AIQWeiboLinkUserPage validCharacterSet:usernameCharacters];

    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
    switch (type) {
        case ResponseTweetTypeOriginal:{

//            // hyperlink topic
//            NSAttributedString *sourceString1 = [self linkifiedStringFromAttributedString:originText2 forPrefixCharacter:@"#" forLinkType:AIQWeiboLinkSearchHash validCharacterSet:hashCharacters];
//            // hyperlink username
//            NSAttributedString *sourceString2 = [self linkifiedStringFromAttributedString:sourceString1 forPrefixCharacter:@"@" forLinkType:AIQWeiboLinkUserPage validCharacterSet:usernameCharacters];

            [attributedString appendAttributedString:originText2];
            
            break;
        }
        case ResponseTweetTypeRetweet:{
            NSDictionary *source = [json objectForKey:@"source"];
            NSString *authorUID = [source objectForKey:@"name"];
            NSString *authorNick = [source objectForKey:@"nick"];
            
//            NSString *sourceText = @"@lunwang #open it# @wanglun";
            NSString *sourceText = [source objectForKey:@"origtext"];
            
            NSAttributedString *sourceString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",sourceText]] autorelease];
            
            // hyperlink topic
            NSAttributedString *sourceString1 = [self linkifiedStringFromAttributedString:sourceString forPrefixCharacter:@"#" forLinkType:AIQWeiboLinkSearchHash validCharacterSet:hashCharacters];
            // hyperlink username
            NSAttributedString *sourceString2 = [self linkifiedStringFromAttributedString:sourceString1 forPrefixCharacter:@"@" forLinkType:AIQWeiboLinkUserPage validCharacterSet:usernameCharacters];

            
            [attributedString appendAttributedString:originText2];
            [attributedString appendAttributedString:sourceString2];
            break;
        }
        case ResponseTweetTypePrivateMessage:
            //            break;
        case ResponseTweetTypeReply:
            //            break;
        case ResponseTweetTypeReplyNull:
            //            break;
        case ResponseTweetTypeMentioned:
            //            break;
        case ResponseTweetTypeComment:
            //            break;
        default:{
            NSDictionary *source = [json objectForKey:@"source"];
            NSString *sourceText = [source objectForKey:@"origtext"];
            NSAttributedString *string = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",originText]] autorelease];
            NSAttributedString *sourceString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",sourceText]] autorelease];
            
            // hyperlink topic
            NSAttributedString *sourceString1 = [self linkifiedStringFromAttributedString:sourceString forPrefixCharacter:@"#" forLinkType:AIQWeiboLinkSearchHash validCharacterSet:hashCharacters];
            // hyperlink username
            NSAttributedString *sourceString2 = [self linkifiedStringFromAttributedString:sourceString1 forPrefixCharacter:@"@" forLinkType:AIQWeiboLinkUserPage validCharacterSet:usernameCharacters];
            
            [attributedString appendAttributedString:string];
            [attributedString appendAttributedString:sourceString2];
            break;
        }
    }
    return attributedString;
}

+(NSAttributedString *)linkifiedStringFromAttributedString:(NSAttributedString *)inString
										forPrefixCharacter:(NSString *)prefixCharacter
											   forLinkType:(AIQWeiboLinkType)linkType
										 validCharacterSet:(NSCharacterSet *)validValues
{
	NSMutableAttributedString	*newString = [inString mutableCopy];
	
	NSScanner		*scanner = [NSScanner scannerWithString:[inString string]];
	
	[scanner setCharactersToBeSkipped:nil];
	
	[newString beginEditing];
	
	while(!scanner.isAtEnd) {
		[scanner scanUpToString:prefixCharacter intoString:NULL];
		
		if(scanner.isAtEnd) {
			break;
		}
		
		NSUInteger	startLocation = scanner.scanLocation;
		NSString	*linkText = nil;
        
		// Advance to the start of the string we want.
		// Check to make sure we aren't exceeding the string bounds.
		if(startLocation + 1 < scanner.string.length) {
			scanner.scanLocation++;
		} else {
			break;
		}
		
		// Grab any valid characters we can.
		BOOL scannedCharacters = [scanner scanCharactersFromSet:validValues intoString:&linkText];
		
		if(scannedCharacters) {
            NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            
			if((scanner.scanLocation - linkText.length) == prefixCharacter.length || 
			   [characterSet characterIsMember:[scanner.string characterAtIndex:(scanner.scanLocation - linkText.length - prefixCharacter.length - 1)]]) {
				
				NSString *linkURL = nil;
				if(linkType == AIQWeiboLinkUserPage) {
					linkURL = [self addressForLinkType:linkType userID:[linkText stringByEncodingURLEscapes] statusID:nil context:nil];
				} else if (linkType == AIQWeiboLinkSearchHash) {
					linkURL = [self addressForLinkType:linkType userID:nil statusID:nil context:[linkText stringByEncodingURLEscapes]];
				} else if (linkType == AIQWeiboLinkGroup) {
					linkURL = [self addressForLinkType:linkType userID:nil statusID:nil context:[linkText stringByEncodingURLEscapes]];
				}
				
				if(linkURL) {
					[newString addAttribute:NSLinkAttributeName
									  value:linkURL
									  range:NSMakeRange(startLocation + 1, linkText.length)];
				}
			}
		} else {
			scanner.scanLocation++;
		}
	}
	
	[newString endEditing];
	
	return [newString autorelease];
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
