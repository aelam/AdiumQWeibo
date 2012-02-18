//
//  AdiumQWeiboEngine.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-14.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "WeiboEngine.h"
#import "JSON.h"


typedef enum {
    RequestTweetTypeOriginal       = 0x1,
    RequestTweetTypeRetweet        = 0x2,
    RequestTweetTypeReply          = 0x8,
    RequestTweetTypeRetweetNull    = 0x10,
    RequestTweetTypeMetioned       = 0x20,
    RequestTweetTypeComment        = 0x40,
} RequestTweetType;

typedef enum {
    ResponseTweetTypeOriginal       = 1,
    ResponseTweetTypeRetweet        = 2,
    ResponseTweetTypePrivateMessage = 3,
    ResponseTweetTypeReply          = 4,
    ResponseTweetTypeReplyNull      = 5,
    ResponseTweetTypeMentioned      = 6,
    ResponseTweetTypeComment        = 7,
} ResponseTweetType;

typedef enum {
	AIQWeiboLinkReply = 0,
	AIQWeiboLinkRetweet,
	AIQWeiboLinkQuote,
	AIQWeiboLinkFavorite,
	AIQWeiboLinkStatus,
	AIQWeiboLinkFriends,
    AIQWeiboLinkFollowings,
    AIQWeiboLinkTweetCount,
	AIQWeiboLinkFollowers,
	AIQWeiboLinkUserPage,
	AIQWeiboLinkSearchHash,
	AIQWeiboLinkGroup,
	AIQWeiboLinkDestroyStatus,
	AIQWeiboLinkDestroyDM
} AIQWeiboLinkType;

typedef enum {
    AdiumQWeiboRequestTypeUserInfo,
    AdiumQWeiboRequestTypeFavorite,
    AdiumQWeiboRequestTypeAddContact,
    AdiumQWeiboRequestTypeDeleteContact,
    AdiumQWeiboRequestTypeUnknown
}AdiumQWeiboRequestType;


typedef enum{
    PageFlagFirstPage,
    PageFlagPageDown,
    PageFlagPageUp
} PageFlag;

typedef void(^JSONRequestHandler)(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error);

typedef BOOL(^PageableJSONRequestHandler)(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error);


@interface AdiumQWeiboEngine : WeiboEngine {
    NSInteger       engineId;
    AdiumQWeiboRequestType  requestType;
}

+ (void)fetchDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;
+ (void)postDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;


+ (void)fetchMyInfoWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;


+ (void)fetchUserInfoWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;

// 我收听的人
+ (void)fetchFollowingListWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;

// Test
// 我收听的人
+ (void)fetchFollowingListFromPage:(NSInteger)page session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;

// 我的听众
+ (void)fetchFollowersListWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;

// 获取用户信息
+ (void)fetchUserInfoWithUID:(NSString *)UID session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;

// 获取用户的推
+ (void)fetchStatusWithUID:(NSString *)UID session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;


+ (void)sendPrivateMessageWithSession:(QOAuthSession *)aSession message:(NSString *)message toUser:(NSString *)username resultHandler:(JSONRequestHandler)handler;

+ (void)fetchPublicTimelineWithSession:(QOAuthSession *)aSession position:(NSInteger)position count:(NSInteger)count resultHandler:(JSONRequestHandler)handler;
+ (void)fetchHomeTimelineWithSession:(QOAuthSession *)aSession pageTime:(double)date pageFlag:(PageFlag)pageFlag count:(NSInteger)count resultHandler:(JSONRequestHandler)handler;
+ (void)fetchUserTimelineWithSession:(QOAuthSession *)aSession forUser:(NSString *)username since:(NSDate *)date lastID:(NSInteger)lastID pageFlag:(PageFlag)pageFlag count:(NSInteger)count resultHandler:(JSONRequestHandler)handler;

+ (void)followUserWithSession:(QOAuthSession *)aSession user:(NSString *)user resultHandler:(JSONRequestHandler)handler;
+ (void)unfollowUserWithSession:(QOAuthSession *)aSession user:(NSString *)user resultHandler:(JSONRequestHandler)handler;

+ (void)deleteTweetWithSession:(QOAuthSession *)aSession tweetID:(NSString *)anID resultHandler:(JSONRequestHandler)handler;
+ (void)favoriteTweetWithSession:(QOAuthSession *)aSession tweetID:(NSString *)anID resultHandler:(JSONRequestHandler)handler;

+ (void)sendTweetWithSession:(QOAuthSession *)aSession content:(NSString *)content resultHandler:(JSONRequestHandler)handler;

+ (void)updateHeadIcon:(NSData *)imageData session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;


@end
