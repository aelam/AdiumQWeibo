//
//  NSError+QWeiboError.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "NSError+QWeiboError.h"

#define QWEIBO_ERROR_DOMAIN @"weibo request error"

@implementation NSError (QWeiboError)

+ (NSError *)errorWithErrorCode:(NSInteger)code errorMessage:(NSString *)message {
    NSError *error = [[NSError alloc] initWithDomain:QWEIBO_ERROR_DOMAIN code:code userInfo:nil];

    return [error autorelease];
}

@end
