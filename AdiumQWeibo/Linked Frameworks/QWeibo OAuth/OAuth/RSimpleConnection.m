//
//  RSimpleConnection.m
//  GTask-iOS
//
//  Created by ryan on 11-9-21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "RSimpleConnection.h"

@implementation RSimpleConnection

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(CompletionHandler)handler {
    
    if (!queue) {
        queue = [NSOperationQueue mainQueue];
    }
    NSBlockOperation *operation  = [NSBlockOperation blockOperationWithBlock:^{
        NSError *anError = nil;
        NSURLResponse *aResponse = nil;
        NSData *responsingData = [NSURLConnection sendSynchronousRequest:request returningResponse:&aResponse error:&anError];
        handler(responsingData,aResponse,anError);
    }];
    [queue addOperation:operation];
}

@end


