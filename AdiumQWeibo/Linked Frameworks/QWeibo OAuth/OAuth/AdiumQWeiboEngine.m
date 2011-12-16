//
//  AdiumQWeiboEngine.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-14.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AdiumQWeiboEngine.h"
#import "QOAuthSession.h"

static NSString *const APIDomain = @"http://open.t.qq.com/api";

@implementation AdiumQWeiboEngine

+ (void)fetchMyInfoWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"user/info";
//    NSString *url = [APIDomain stringByAppendingFormat:@"/%@",path];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",nil];
    
//    AdiumQWeiboEngine *engine = [[[AdiumQWeiboEngine alloc] initWithURL:[NSURL URLWithString:url] parameters:params requestMethod:RequestMethodGET] autorelease];
//    engine.session = aSession;
//    
//    [engine performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        
//        NSDictionary *json = [responseData JSONValue];
//        handler(json,urlResponse,error);            
//    }];    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];

}


+ (void)fetchUserInfoWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {

    NSString *path = @"user/info";

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",nil];
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];

}

//
// 我收听的人
//
+ (void)fetchFollowingListWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"friends/idollist";
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",nil];
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);

        NSInteger hasNext = [[responseJSON valueForKeyPath:@"data.hasnext"] intValue];

        if (!error && hasNext == 0) {
            [self fetchFollowersListWithSession:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                handler(responseJSON,urlResponse,error);
            }];
        }
    }];
}

#define PAGE_SIZE_   @"30"

+ (void)fetchFollowingListFromPage:(NSInteger)page session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"friends/idollist";
        
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",PAGE_SIZE_,@"reqnum",[NSString stringWithFormat:@"%d",page],@"startindex",nil];
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);

        NSInteger hasNext = [[responseJSON valueForKeyPath:@"data.hasnext"] intValue];
        
        if (!error && hasNext == 0) {
            NSInteger page_ = page + 1;
            [self fetchFollowingListFromPage:page_ session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                handler(responseJSON,urlResponse,error);
            }];
        }
    }];
}

//
// 我的听众
//
+ (void)fetchFollowersListWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"friends/fanslist";
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",nil];
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];
    
}

//
// 获取用户信息
//
+ (void)fetchUserInfoWithUID:(NSString *)UID session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"user/other_info";

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",UID,@"name",nil];
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];
}

// Start Point
+ (void)fetchDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *url = [APIDomain stringByAppendingFormat:@"/%@",path];
    
    AdiumQWeiboEngine *engine = [[[AdiumQWeiboEngine alloc] initWithURL:[NSURL URLWithString:url] parameters:params requestMethod:RequestMethodGET]autorelease];
    engine.session = aSession;
    
    [engine performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSDictionary *json = [responseData JSONValue];
        handler(json,urlResponse,error);            
    }];
}


@end
