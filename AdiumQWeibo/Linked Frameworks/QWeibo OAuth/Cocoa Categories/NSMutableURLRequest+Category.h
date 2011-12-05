//
//  NSMutableURLRequest+Category.h
//  QWeibo
//
//  Created by Ryan Wang on 11-11-30.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QOAuthSession.h"

@interface NSMutableURLRequest (Category)

//Return a request for http get method
+ (NSMutableURLRequest *)requestGet:(NSString *)aUrl queryString:(NSString *)aQueryString;

//Return a request for http post method
+ (NSMutableURLRequest *)requestPost:(NSString *)aUrl queryString:(NSString *)aQueryString;

//Return a request for http post with multi-part method
+ (NSMutableURLRequest *)requestPostWithFile:(NSDictionary *)files url:(NSString *)aUrl queryString:(NSString *)aQueryString;

@end
