//
//  OAuthURLRequest.h
//  QWeibo
//
//  Created by Ryan Wang on 11-12-1.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QOAuthSession.h"


@interface OAuthURLRequest : NSMutableURLRequest 


+ (OAuthURLRequest *)requestWithURL:(NSString *)url parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method session:(QOAuthSession *)aSession;

+ (OAuthURLRequest *)requestWithURL:(NSString *)url callBackURL:(NSString *)callBackURL parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method session:(QOAuthSession *)aSession;

+ (OAuthURLRequest *)requestWithURL:(NSString *)url verify:(NSString *)verify parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method session:(QOAuthSession *)aSession;


+ (OAuthURLRequest *)requestWithURL:(NSString *)url parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method files:(NSDictionary *)files session:(QOAuthSession *)aSession;


@end
