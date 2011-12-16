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
    AdiumQWeiboRequestTypeUserInfo,
    AdiumQWeiboRequestTypeFavorite,
    AdiumQWeiboRequestTypeAddContact,
    AdiumQWeiboRequestTypeDeleteContact,
    AdiumQWeiboRequestTypeUnknown
}AdiumQWeiboRequestType;


typedef void(^JSONRequestHandler)(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error);

typedef BOOL(^PageableJSONRequestHandler)(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error);


@interface AdiumQWeiboEngine : WeiboEngine {
    NSInteger       engineId;
    AdiumQWeiboRequestType  requestType;
}

+ (void)fetchDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;


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



@end
