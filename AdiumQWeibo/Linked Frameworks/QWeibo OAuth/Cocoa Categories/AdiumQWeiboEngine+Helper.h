//
//  AdiumQWeiboEngine+Helper.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-18.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdiumQWeiboEngine.h"

@interface AdiumQWeiboEngine (Helper)

+ (NSString *)addressForLinkType:(AIQWeiboLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context;


+ (NSAttributedString *)attributedTweetForPlainText:(NSString *)tweet replacingNicknames:(NSDictionary *)nicknamePairs;
+ (NSAttributedString *)attributedTweetForPlainText:(NSString *)tweet replacingNicknames:(NSDictionary *)nicknamePairs processEmotion:(BOOL)needProcess;
+ (NSArray *)attributedTweetsFromTweetDictionary:(NSDictionary *)json;
+ (NSArray *)attributedTweetsFromTweetDictionary:(NSDictionary *)json processEmotion:(BOOL)needProcess;

+ (NSAttributedString *)attributedUserWithName:(NSString *)name nick:(NSString *)nick;



+(NSAttributedString *)linkifiedStringFromAttributedString:(NSAttributedString *)inString
										forPrefixCharacter:(NSString *)prefixCharacter
											   forLinkType:(AIQWeiboLinkType)linkType
										 validCharacterSet:(NSCharacterSet *)validValues;

@end
