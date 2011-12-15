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

+ (void)fetchUserInfoWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"user/info";
    NSString *url = [APIDomain stringByAppendingFormat:@"/%@",path];

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",nil];
    
    AdiumQWeiboEngine *engine = [[AdiumQWeiboEngine alloc] initWithURL:[NSURL URLWithString:url] parameters:params requestMethod:RequestMethodGET];
    engine.session = aSession;
        
    [engine performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSDictionary *json = [responseData JSONValue];
        handler(json,urlResponse,error);            
    }];
}

+ (void)fetchUsersListWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"friends/fanslist";
    NSString *url = [APIDomain stringByAppendingFormat:@"/%@",path];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",nil];
    
    AdiumQWeiboEngine *engine = [[AdiumQWeiboEngine alloc] initWithURL:[NSURL URLWithString:url] parameters:params requestMethod:RequestMethodGET];
    engine.session = aSession;
    
    [engine performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSDictionary *json = [responseData JSONValue];
        handler(json,urlResponse,error);            
    }];
    
}


@end
