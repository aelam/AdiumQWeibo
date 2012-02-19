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
static NSString *const WeiboErrorDomain = @"WeiboErrorDomain";

@interface AdiumQWeiboEngine(Private)

+ (void)_requestDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession requestMethod:(RequestMethod)method resultHandler:(JSONRequestHandler)handler;

+ (void)_requestDataWithAPIPath:(NSString *)path params:(NSDictionary *)params imageData:(NSData *)imageData session:(QOAuthSession *)aSession requestMethod:(RequestMethod)method resultHandler:(JSONRequestHandler)handler;


@end

@implementation AdiumQWeiboEngine

+ (void)fetchMyInfoWithSession:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"user/info";
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",nil];
    
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

        NSInteger hasNext = -1;
        id data = [responseJSON objectForKey:@"data"];
        if (data && [data respondsToSelector:@selector(objectForKey:)]) {
            id hasnext_ = [data objectForKey:@"hasnext"];
            if (hasnext_) {
                hasNext = [hasnext_ intValue];
            }
        }

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

        NSInteger hasNext = -1;
        id data = [responseJSON objectForKey:@"data"];
        if (data && [data respondsToSelector:@selector(objectForKey:)]) {
            id hasnext_ = [data objectForKey:@"hasnext"];
            if (hasnext_) {
                hasNext = [hasnext_ intValue];
            }
        }
      
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


/*!
 * @brief Send Message to some user
 * 
 *
 */

+ (void)sendPrivateMessageWithSession:(QOAuthSession *)aSession message:(NSString *)message toUser:(NSString *)username resultHandler:(JSONRequestHandler)handler{
    NSString *path = @"private/add";
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"json",@"format",
                                message,@"content",
                                username,@"name",
                                @"127.0.0.1",@"clientip",
                                @"",@"jing",
                                @"",@"wei",nil
                            ];
    [self postDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];

}


/*!
 * @brief get 
 * 
 * @prama pos       记录的起始位置（第一次请求时填0，继续请求时填上次请求返回的pos）
 * @prama reqnum    每次请求记录的条数（1-70条）
 *
 */

+ (void)fetchPublicTimelineWithSession:(QOAuthSession *)aSession position:(NSInteger)position count:(NSInteger)count resultHandler:(JSONRequestHandler)handler{
    NSString *path = @"statuses/public_timeline";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:[NSString stringWithFormat:@"%d",position] forKey:@"pos"];
    [params setObject:[NSString stringWithFormat:@"%d",count] forKey:@"reqnum"];
    [params setObject:@"json" forKey:@"format"];
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];
}


/*!
 * @brief Send Message to some user
 * 
 * @prama pageflag  分页标识（0：第一页，1：向下翻页，2：向上翻页）
 * @prama pagetime  本页起始时间（第一页：填0，向上翻页：填上一次请求返回的第一条记录时间，向下翻页：填上一次请求返回的最后一条记录时间）
 * @prama reqnum    每次请求记录的条数（1-70条）
 *
 */

+ (void)fetchHomeTimelineWithSession:(QOAuthSession *)aSession pageTime:(double)date pageFlag:(PageFlag)pageFlag count:(NSInteger)count resultHandler:(JSONRequestHandler)handler{

    NSString *path = @"statuses/home_timeline";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];

    [params setObject:[NSString stringWithFormat:@"%0.0f",date] forKey:@"pagetime"];
        
    [params setObject:[NSString stringWithFormat:@"%d",pageFlag] forKey:@"pageflag"];
    [params setObject:[NSString stringWithFormat:@"%d",count] forKey:@"reqnum"];
    [params setObject:@"json" forKey:@"format"];
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];
}

+ (void)fetchUserTimelineWithSession:(QOAuthSession *)aSession forUser:(NSString *)username since:(NSDate *)date lastID:(NSInteger)lastID pageFlag:(PageFlag)pageFlag count:(NSInteger)count resultHandler:(JSONRequestHandler)handler{
    NSString *path = @"statuses/user_timeline";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:username forKey:@"name"];
    
    [params setObject:[NSString stringWithFormat:@"%d",pageFlag] forKey:@"pageflag"];
    [params setObject:[NSString stringWithFormat:@"%d",count] forKey:@"reqnum"];
    [params setObject:@"json" forKey:@"format"];

    if (date) {
        [params setObject:[NSString stringWithFormat:@"%@",[date timeIntervalSince1970]] forKey:@"pagetime"];
    }
    
    [self fetchDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];
}

/**
 * follow somebody 
 * friends/add
 *
 */
+ (void)followUserWithSession:(QOAuthSession *)aSession user:(NSString *)user resultHandler:(JSONRequestHandler)handler{
    NSString *path = @"friends/add";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:@"json" forKey:@"format"];
    [params setObject:user forKey:@"name"];
    
    [self postDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);
    }];
}

+ (void)unfollowUserWithSession:(QOAuthSession *)aSession user:(NSString *)user resultHandler:(JSONRequestHandler)handler{
    NSString *path = @"friends/del";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:@"json" forKey:@"format"];
    [params setObject:user forKey:@"name"];
    
    [self postDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);
    }];
}



+ (void)deleteTweetWithSession:(QOAuthSession *)aSession tweetID:(NSString *)anID resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"t/del";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:@"json" forKey:@"format"];
    [params setObject:anID forKey:@"id"];
    
    [self postDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);
    }];

}

+ (void)favoriteTweetWithSession:(QOAuthSession *)aSession tweetID:(NSString *)anID resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"fav/addt";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:@"json" forKey:@"format"];
    [params setObject:anID forKey:@"id"];
    
    [self postDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);
    }];    
}

+ (void)sendTweetWithSession:(QOAuthSession *)aSession content:(NSString *)content resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"t/add";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:@"json" forKey:@"format"];
    [params setObject:content forKey:@"content"];
    [self postDataWithAPIPath:path params:params session:aSession resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);
    }];    

}

+ (void)updateHeadIcon:(NSData *)imageData session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    NSString *path = @"user/update_head";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:@"json" forKey:@"format"];
    
    [self _requestDataWithAPIPath:path params:params imageData:imageData session:aSession requestMethod:RequestMethodPOST resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);
    }];
}


//////////////////////////////////////////////////////////////////////////
//                                                                      //
// Start Point                                                          //
//                                                                      //
//////////////////////////////////////////////////////////////////////////
+ (void)fetchDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    [self _requestDataWithAPIPath:path params:params session:aSession requestMethod:RequestMethodGET resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];

}

+ (void)postDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession resultHandler:(JSONRequestHandler)handler {
    [self _requestDataWithAPIPath:path params:params session:aSession requestMethod:RequestMethodPOST resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);            
    }];
}

+ (void)_requestDataWithAPIPath:(NSString *)path params:(NSDictionary *)params session:(QOAuthSession *)aSession requestMethod:(RequestMethod)method resultHandler:(JSONRequestHandler)handler {
    [self _requestDataWithAPIPath:path params:params imageData:nil session:aSession requestMethod:method resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        handler(responseJSON,urlResponse,error);
    }];
    
}

+ (void)_requestDataWithAPIPath:(NSString *)path params:(NSDictionary *)params imageData:(NSData *)imageData session:(QOAuthSession *)aSession requestMethod:(RequestMethod)method resultHandler:(JSONRequestHandler)handler {
    NSString *url = [APIDomain stringByAppendingFormat:@"/%@",path];
    
    AdiumQWeiboEngine *engine = nil;
    if (imageData) {
        engine = [[[AdiumQWeiboEngine alloc] initWithURL:[NSURL URLWithString:url] parameters:params requestMethod:method]autorelease];
        [engine addMultiPartData:imageData withName:[NSString stringWithFormat:@"%lf",[[NSDate date] timeIntervalSince1970]]];

    } else {
        engine = [[[AdiumQWeiboEngine alloc] initWithURL:[NSURL URLWithString:url] parameters:params requestMethod:method]autorelease];
    }
    engine.session = aSession;
    
    [engine performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (!error && responseData) {
            @try {
                NSDictionary *json = [responseData JSONValue];
                if (json == nil) {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"JSON parse error" forKey:NSLocalizedDescriptionKey];
                    NSError *weiboError = [NSError errorWithDomain:WeiboErrorDomain code:1000000 userInfo:userInfo];
                    handler(nil,urlResponse,weiboError);
                } else {
                    int returnCode = [[json objectForKey:@"ret"] intValue];
                    int errorCode = [[json objectForKey:@"errcode"] intValue];
                    NSString *errorMessage = [json objectForKey:@"msg"];
                    if (returnCode != 0 || errorCode != 0) {
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey];
                        NSInteger weiboErrorCode = returnCode * 10000 + errorCode;
                        NSError *weiboError = [NSError errorWithDomain:WeiboErrorDomain code:weiboErrorCode userInfo:userInfo];                
                        handler(json,urlResponse,weiboError);            
                    } else {
                        handler(json,urlResponse,nil);                                    
                    }
                }
            }
            @catch (NSException *exception) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Exception Error" forKey:NSLocalizedDescriptionKey];
                NSInteger exceptionErrorCode = 10000;
                NSError *weiboError = [NSError errorWithDomain:WeiboErrorDomain code:exceptionErrorCode userInfo:userInfo]; 
                NSString *s1 = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
                handler(nil,urlResponse,weiboError);
            }
            @finally {
                
            }
            
        } else {
            handler(nil,urlResponse,error);            
        }        
    }];
    
}

@end
