//
//  OAuthURLRequest.m
//  QWeibo
//
//  Created by Ryan Wang on 11-12-1.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "OAuthURLRequest.h"
#import "NSURL+QAdditions.h"

@implementation OAuthURLRequest

+ (OAuthURLRequest *)requestWithURL:(NSString *)url parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method session:(QOAuthSession *)aSession {
    return [self requestWithURL:url callBackURL:nil parameters:parameters HTTPMethod:method session:aSession];
}


+ (OAuthURLRequest *)requestWithURL:(NSString *)url callBackURL:(NSString *)callBackURL parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method session:(QOAuthSession *)aSession {

    OAuthURLRequest *request = nil;
    
    NSString *queries = nil;
    NSString *oauthURL = [aSession getOauthUrl:url httpMethod:method verify:nil callbackUrl:callBackURL parameters:parameters queryString:&queries];

    NSString *requestURL = nil;
    if ([[method uppercaseString]isEqualToString:@"GET"]) {
        requestURL = [NSString stringWithFormat:@"%@?%@",oauthURL,queries];            
        request = [[[self alloc] initWithURL:[NSURL smartURLForString:requestURL]] autorelease];
        
    } else if ([[method uppercaseString]isEqualToString:@"POST"]) {
        [request setHTTPMethod:@"POST"];
        [request setTimeoutInterval:20.0f];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[queries dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        
    }
    return request;
}

+ (OAuthURLRequest *)requestWithURL:(NSString *)url verify:(NSString *)verify parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method session:(QOAuthSession *)aSession {
    OAuthURLRequest *request = nil;
    
    NSString *queries = nil;
    NSString *oauthURL = [aSession getOauthUrl:url httpMethod:method verify:verify callbackUrl:nil parameters:parameters queryString:&queries];
    
    NSString *requestURL = nil;
    if ([[method uppercaseString]isEqualToString:@"GET"]) {
        requestURL = [NSString stringWithFormat:@"%@?%@",oauthURL,queries];            
        request = [[[self alloc] initWithURL:[NSURL smartURLForString:requestURL]] autorelease];
        
    } else if ([[method uppercaseString]isEqualToString:@"POST"]) {
        [request setHTTPMethod:@"POST"];
        [request setTimeoutInterval:20.0f];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[queries dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        
    }
    return request;
    
}



+ (OAuthURLRequest *)requestWithURL:(NSString *)url parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)method files:(NSDictionary *)files session:(QOAuthSession *)aSession {
    
    if (files &&[files count]) {
        NSString *aQueryString = nil;
        NSString *oauthURL = [aSession getOauthUrl:url httpMethod:@"POST" verify:nil callbackUrl:nil parameters:parameters queryString:&aQueryString];
        
        OAuthURLRequest *request = [[[OAuthURLRequest alloc] initWithURL:[NSURL smartURLForString:oauthURL]] autorelease];
        [request setHTTPMethod:@"POST"];
        [request setTimeoutInterval:20.0f];
        
        
        //generate boundary string
        CFUUIDRef       uuid;
        CFStringRef     uuidStr;
        uuid = CFUUIDCreate(NULL);
        assert(uuid != NULL);
        uuidStr = CFUUIDCreateString(NULL, uuid);
        assert(uuidStr != NULL);
        NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", uuidStr];
        CFRelease(uuidStr);
        CFRelease(uuid);
        
        NSData *boundaryBytes = [[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
        [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
        
        NSMutableData *bodyData = [NSMutableData data];
        NSString *formDataTemplate = @"\r\n--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@";
        
        NSDictionary *listParams = [NSURL parseURLQueryString:aQueryString];
        for (NSString *key in listParams) {
            
            NSString *value = [listParams valueForKey:key];
            NSString *formItem = [NSString stringWithFormat:formDataTemplate, boundary, key, value];
            [bodyData appendData:[formItem dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [bodyData appendData:boundaryBytes];
        
        NSString *headerTemplate = @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: \"application/octet-stream\"\r\n\r\n";
        for (NSString *key in files) {
            
            NSData *fileData = [files objectForKey:key];
            NSString *header = [NSString stringWithFormat:headerTemplate, @"pic", @"name"];
            [bodyData appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
            [bodyData appendData:fileData];
            [bodyData appendData:boundaryBytes];
        }
        //[request setValue:[NSString stringWithFormat:@"%d", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:bodyData];
        NIF_INFO(@"body %s", [bodyData bytes]);
        
        return request;        
    } else {
        OAuthURLRequest *request = nil;
        
        NSString *queries = nil;
        /*NSString *oauthURL = */
        [aSession getOauthUrl:url httpMethod:method verify:nil callbackUrl:nil parameters:parameters queryString:&queries];
        
        NSString *requestURL = nil;
        if ([[method uppercaseString]isEqualToString:@"GET"]) {
            requestURL = [NSString stringWithFormat:@"%@?%@",url,queries];            
            request = [[[self alloc] initWithURL:[NSURL smartURLForString:requestURL]] autorelease];
            
        } else if ([[method uppercaseString]isEqualToString:@"POST"]) {
            request = [[[self alloc] initWithURL:[NSURL smartURLForString:url]] autorelease];
            [request setHTTPMethod:@"POST"];
            [request setTimeoutInterval:20.0f];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[queries dataUsingEncoding:NSUTF8StringEncoding]];
            NIF_INFO(@"post request : %@", request);
            NIF_INFO(@"post request : %@", [request URL]);
            
        } else {
            
        }
        return request;

    }
}

- (void)dealloc {
    [super dealloc];
}

@end
