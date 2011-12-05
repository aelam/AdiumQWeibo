//
//  NSDictionary+Response.h
//  QWeibo
//
//  Created by Ryan Wang on 11-12-2.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Response)

+ (NSDictionary *)oauthTokenPairsFromResponse:(NSString *)queryString;

@end
