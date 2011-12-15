//
//  NSError+QWeiboError.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (QWeiboError)

+ (NSError *)errorWithErrorCode:(NSInteger)code errorMessage:(NSString *)message;

@end
