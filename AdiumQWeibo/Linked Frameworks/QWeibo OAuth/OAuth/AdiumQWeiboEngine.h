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


@interface AdiumQWeiboEngine : WeiboEngine {
    NSInteger       engineId;
    AdiumQWeiboRequestType  requestType;
}

+ (void)fetchUserInfoWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;

+ (void)fetchUsersListWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler;


@end
