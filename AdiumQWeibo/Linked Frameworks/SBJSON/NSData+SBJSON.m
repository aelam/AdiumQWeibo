//
//  NSData+SBJSON.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-15.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "NSData+SBJSON.h"
#import "NSString+SBJSON.h"

@implementation NSData(SBJSON)

- (id)JSONValue {
    NSString *res = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
    id json = [res JSONValue];
    [res release];
    return json;
}
@end
