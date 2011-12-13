//
//  WeiboEngine.h
//  QWeibo
//
//  Created by Ryan Wang on 11-11-30.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QOAuthSession.h"

@class OAuthURLRequest;

enum RequestMethod {
    RequestMethodGET,
    RequestMethodPOST,
    RequestMethodDELETE
};
typedef enum RequestMethod RequestMethod; 


typedef void(^RequestHandler)(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error);


@interface WeiboEngine : NSObject {
    NSOperationQueue        *_operationQueue;
    NSMutableDictionary     *_multiParts;
        
    void (^accessTokenHandler)(NSString *text,BOOL success);
    
    QOAuthSession *_session;
    
    RequestMethod _requestMethod;
    
    NSURL *_URL;
    
    NSDictionary *_parameters;

    
}

@property (nonatomic, retain) QOAuthSession *session;

@property (nonatomic, readonly) RequestMethod requestMethod;

@property (nonatomic, readonly) NSURL *URL;

@property (nonatomic, readonly) NSDictionary *parameters;

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(RequestMethod)requestMethod;

- (void)addMultiPartData:(NSData*)data withName:(NSString*)name;

- (void)performRequestWithHandler:(RequestHandler)handler;

- (BOOL)handleOpenURL:(NSURL *)url;

// test
- (void)authorizeWithBlock:(void(^)(NSString *desc,BOOL success))resultBlock;


@end
