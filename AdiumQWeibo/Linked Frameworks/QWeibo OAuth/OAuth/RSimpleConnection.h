//
//  RSimpleConnection.h
//  GTask-iOS
//
//  Created by ryan on 11-9-21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

@interface RSimpleConnection : NSURLConnection

typedef void (^CompletionHandler)(NSData*,NSURLResponse*, NSError*);

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(CompletionHandler)handler;// NS_AVAILABLE(10_7, 4_0);

@end

