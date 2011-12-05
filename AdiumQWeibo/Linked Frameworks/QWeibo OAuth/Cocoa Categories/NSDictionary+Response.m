//
//  NSDictionary+Response.m
//  QWeibo
//
//  Created by Ryan Wang on 11-12-2.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+Response.h"

@implementation NSDictionary (Response)

+ (NSDictionary *)oauthTokenPairsFromResponse:(NSString *)queryString {
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
	for(NSString *pair in pairs) {
		NSArray *keyValue = [pair componentsSeparatedByString:@"="];
		if([keyValue count] == 2) {
			NSString *key = [keyValue objectAtIndex:0];
			NSString *value = [keyValue objectAtIndex:1];
			value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			if(key && value)
				[dict setObject:value forKey:key];
		}
	}
	return [NSDictionary dictionaryWithDictionary:dict];
}

@end
