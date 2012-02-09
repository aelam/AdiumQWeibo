//
//  QOAuthSession.m
//  QWeiboSDK4iOS
//
//  Created on 11-1-12.
//  
//

#import <stdlib.h>
#import <CommonCrypto/CommonHMAC.h>
#import "QOAuthSession.h"
#import "NSString+QEncoding.h"
#import "NSData+QBase64.h"
#import "NSURL+QAdditions.h"

#pragma mark -
#pragma mark Constants

#define OAuthVersion            @"1.0"
#define OAuthParameterPrefix    @"oauth_"
#define OAuthConsumerKeyKey     @"oauth_consumer_key"
#define OAuthCallbackKey        @"oauth_callback"
#define OAuthVersionKey         @"oauth_version"
#define OAuthSignatureMethodKey @"oauth_signature_method"
#define OAuthSignatureKey       @"oauth_signature"
#define OAuthTimestampKey       @"oauth_timestamp"
#define OAuthNonceKey           @"oauth_nonce"
#define OAuthTokenKey           @"oauth_token"
#define oAauthVerifier          @"oauth_verifier"
#define OAuthTokenSecretKey     @"oauth_token_secret"
#define HMACSHA1SignatureType   @"HMAC-SHA1"

//#define AppKey		@"801095379"
//#define AppSecret		@"521fac7d698fe6eff6ce7efde15db9c8"
#define AppKey          @"14a6b38d5ffe47c7a9acd86902660cdd"
#define AppSecret       @"3016f15bfcf6990f4fb71b4a368d950f"
#define AppTokenKey		@"tokenKey"
#define AppTokenSecret	@"tokenSecret"
#define USER_NAME       @"USER_NAME"
#define IS_VALID        @"IS_VALID"

#define SESSION_DIC_KEY @"SESSION_DIC_KEY"

#pragma mark -
#pragma mark Static methods

static NSInteger SortParameter(NSString *key1, NSString *key2, void *context) {
	NSComparisonResult r = [key1 compare:key2];
	if(r == NSOrderedSame) { // compare by value in this case
		NSDictionary *dict = (NSDictionary *)context;
		NSString *value1 = [dict objectForKey:key1];
		NSString *value2 = [dict objectForKey:key2];
		return [value1 compare:value2];
	}
	return r;
}

static NSData *HMAC_SHA1(NSString *data, NSString *key) {
	unsigned char buf[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [data UTF8String], [data length], buf);
	return [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
}

#pragma mark -
#pragma mark implementation QOAuthSession

@implementation QOAuthSession

@synthesize consumerKey = _consumerKey;
@synthesize consumerSecret = _consumerSecret;
@synthesize tokenKey = _tokenKey;
@synthesize tokenSecret = _tokenSecret;
@synthesize verify = _verify;
@synthesize callbackUrl = _callbackUrl;
@synthesize username = _username;
@synthesize identifier = _identifier;
@synthesize isValid = _isValid;


- (NSString *)_sessionDictionaryKeyWithId:(NSInteger)identifier {
    NSString *key = [NSString stringWithFormat:@"%@%d",SESSION_DIC_KEY,identifier];
    return key;
}

+ (QOAuthSession *)defaultQOAuthSession {
    return [[[QOAuthSession alloc] initWithIdentifier:@"com.ryan.weibo"] autorelease];
}

- (id)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        _identifier = [identifier copy];

        NSDictionary *pairs = [[NSUserDefaults standardUserDefaults] objectForKey:_identifier];
        
        _tokenKey = [[pairs valueForKey:AppTokenKey]copy];
        _tokenSecret = [[pairs valueForKey:AppTokenSecret]copy];
        _username = [[pairs valueForKey:USER_NAME] copy];
        _isValid = [[pairs valueForKey:IS_VALID]boolValue];
    }
    return self;
}

- (BOOL)isSessionValid {
//    return self.tokenKey && self.tokenSecret;
    return _isValid;
}

- (void)logOut {
    [self setIsValid:NO];
    [self setUsername:nil];
    [self setTokenKey:nil];
    [self setTokenSecret:nil];
}

- (NSString *)consumerKey {
    return AppKey;
}

- (NSString *)consumerSecret {
    return AppSecret;
}

//Normalizes the request parameters according to the spec.
- (NSString *)normalizedRequestParameters:(NSDictionary *)aParameters {
	
	NSMutableArray *parametersArray = [NSMutableArray array];
	for (NSString *key in aParameters) {
		[parametersArray addObject:[NSString stringWithFormat:@"%@=%@", key, [aParameters valueForKey:key]]];
	}
	return [parametersArray componentsJoinedByString:@"&"];
}

//Generate the timestamp for the signature.
- (NSString *)generateTimeStamp {
	
	return [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
}

- (NSString *)generateNonce {
	// Just a simple implementation of a random number between 123400 and 9999999
	return [NSString stringWithFormat:@"%u", arc4random() % (9999999 - 123400) + 123400];
}

//Generate the signature base that is used to produce the signature
- (NSString *)generateSignatureBaseWithUrl:(NSURL *)aUrl 
								httpMethod:(NSString *)aHttpMethod 
								parameters:(NSDictionary *)aParameters 
							 normalizedUrl:(NSString **)aNormalizedUrl 
			   normalizedRequestParameters:(NSString **)aNormalizedRequestParameters {
	
	*aNormalizedUrl = nil;
	*aNormalizedRequestParameters = nil;
	
	if ([aUrl port]) {
		*aNormalizedUrl = [NSString stringWithFormat:@"%@:%@//%@%@", [aUrl scheme], [aUrl port], [aUrl host], [aUrl path]];
	} else {
		*aNormalizedUrl = [NSString stringWithFormat:@"%@://%@%@", [aUrl scheme], [aUrl host], [aUrl path]];
	}
	
	NSMutableArray *parametersArray = [NSMutableArray array];
	NSArray *sortedKeys = [[aParameters allKeys] sortedArrayUsingFunction:SortParameter context:aParameters];
	for (NSString *key in sortedKeys) {
		NSString *value = [aParameters valueForKey:key];
		[parametersArray addObject:[NSString stringWithFormat:@"%@=%@", key, [value URLEncodedString]]];
	}
	*aNormalizedRequestParameters = [parametersArray componentsJoinedByString:@"&"];
	
	NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
									 aHttpMethod, [*aNormalizedUrl URLEncodedString], [*aNormalizedRequestParameters URLEncodedString]];

	return signatureBaseString;
}

//Generates a signature using the HMAC-SHA1 algorithm
- (NSString *)generateSignatureWithUrl:(NSURL *)aUrl
						 customeSecret:(NSString *)aConsumerSecret 
						   tokenSecret:(NSString *)aTokenSecret 
							httpMethod:(NSString *)aHttpMethod 
							parameters:(NSDictionary *)aPatameters 
						 normalizedUrl:(NSString **)aNormalizedUrl 
		   normalizedRequestParameters:(NSString **)aNormalizedRequestParameters {
	
	NSString *signatureBase = [self generateSignatureBaseWithUrl:aUrl 
													  httpMethod:aHttpMethod 
													  parameters:aPatameters 
												   normalizedUrl:aNormalizedUrl 
									 normalizedRequestParameters: aNormalizedRequestParameters];
	
	NSString *signatureKey = [NSString stringWithFormat:@"%@&%@", [aConsumerSecret URLEncodedString], aTokenSecret ? [aTokenSecret URLEncodedString] : @""];
	NSData *signature = HMAC_SHA1(signatureBase, signatureKey);
	NSString *base64Signature = [signature base64EncodedString];
	return base64Signature;
}

#pragma mark -
#pragma mark QOAuthSession instance methods
- (NSString *)getOauthUrl:(NSString *)aUrl 
			   httpMethod:(NSString *)aMethod 
				   verify:(NSString *)aVerify 
			  callbackUrl:(NSString *)aCallbackUrl 
			   parameters:(NSDictionary *)aParameters 
			  queryString:(NSString **)aQueryString {
   	NSString *parameterString = [self normalizedRequestParameters:aParameters];
	NSMutableString *urlWithParameter = [[[NSMutableString alloc] initWithString:aUrl] autorelease];
	if (parameterString && ![parameterString isEqualToString:@""]) {
		[urlWithParameter appendFormat:@"?%@", parameterString];
	}
	
	NSString *encodedUrl = [urlWithParameter stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *url = [NSURL smartURLForString:encodedUrl];
	NSString *nonce = [self generateNonce];
	NSString *timeStamp = [self generateTimeStamp];
	
	NSMutableDictionary *allParameters;
	if (aParameters) {
		allParameters = [[aParameters mutableCopy] autorelease];
	} else {
		allParameters = [NSMutableDictionary dictionary];
	}
    
	[allParameters setObject:nonce forKey:OAuthNonceKey];
	[allParameters setObject:timeStamp forKey:OAuthTimestampKey];
	[allParameters setObject:OAuthVersion forKey:OAuthVersionKey];
	[allParameters setObject:HMACSHA1SignatureType forKey:OAuthSignatureMethodKey];
	[allParameters setObject:self.consumerKey forKey:OAuthConsumerKeyKey];
	if (self.tokenKey) {
		[allParameters setObject:self.tokenKey forKey:OAuthTokenKey];
	}
	if (aVerify) {
		[allParameters setObject:aVerify forKey:oAauthVerifier];
	}
	if (aCallbackUrl) {
		[allParameters setObject:aCallbackUrl forKey:OAuthCallbackKey];
	}
	
	NSString *normalizedURL = nil;
	NSMutableString *queryString = nil;
	NSString *signature = [self generateSignatureWithUrl:url 
										   customeSecret:self.consumerSecret 
											 tokenSecret:self.tokenSecret 
											  httpMethod:aMethod 
											  parameters:allParameters 
										   normalizedUrl:&normalizedURL 
							 normalizedRequestParameters:&queryString];
	[queryString appendFormat:@"&oauth_signature=%@", [signature URLEncodedString]];
	*aQueryString = [[[NSString alloc] initWithString:queryString] autorelease];
	
	return normalizedURL;
 
}

- (void)setTokenKey:(NSString *)text {
    if (![_tokenKey isEqualToString:text]) {
        [_tokenKey release];
        _tokenKey = [text copy];
        
        NSDictionary *pairs = [[NSUserDefaults standardUserDefaults]dictionaryForKey:_identifier];
        NSMutableDictionary *mutablePairs = [NSMutableDictionary dictionaryWithDictionary:pairs];
        if (_tokenKey) {
            [mutablePairs setObject:_tokenKey forKey:AppTokenKey];
        } else {
            [mutablePairs removeObjectForKey:AppTokenKey];
        }
        [[NSUserDefaults standardUserDefaults] setObject:mutablePairs forKey:_identifier];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

- (void)setTokenSecret:(NSString *)text {
    if (![_tokenSecret isEqualToString:text]) {
        [_tokenSecret release];
        _tokenSecret = [text copy];
        

        NSDictionary *pairs = [[NSUserDefaults standardUserDefaults]dictionaryForKey:_identifier];
        NSMutableDictionary *mutablePairs = [NSMutableDictionary dictionaryWithDictionary:pairs];
        if (_tokenSecret) {
            [mutablePairs setObject:_tokenSecret forKey:AppTokenSecret];
        } else {
            [mutablePairs removeObjectForKey:AppTokenSecret];
        }
        [[NSUserDefaults standardUserDefaults] setObject:mutablePairs forKey:_identifier];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

- (NSString *)username {
    return _username;
}

- (void)setUsername:(NSString *)text {
    if (![_username isEqualToString:text]) {
        [_username release];
        _username = [text copy];
        
        NSDictionary *pairs = [[NSUserDefaults standardUserDefaults]dictionaryForKey:_identifier];
        NSMutableDictionary *mutablePairs = [NSMutableDictionary dictionaryWithDictionary:pairs];
        if (_username) {
            [mutablePairs setObject:_username forKey:USER_NAME];
        } else {
            [mutablePairs removeObjectForKey:USER_NAME];
        }
        [[NSUserDefaults standardUserDefaults] setObject:mutablePairs forKey:_identifier];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

- (void)setIsValid:(BOOL)valid {
    if (_isValid != valid) {
        _isValid = valid;
            
    NSDictionary *pairs = [[NSUserDefaults standardUserDefaults]dictionaryForKey:_identifier];
        NSMutableDictionary *mutablePairs = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [mutablePairs setObject:[NSNumber numberWithBool:_isValid] forKey:IS_VALID];

        [[NSUserDefaults standardUserDefaults] setObject:mutablePairs forKey:_identifier];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

- (NSString *)description {
    NSDictionary *pairs = [[NSUserDefaults standardUserDefaults]dictionaryForKey:_identifier];
    NSMutableArray *queries = [NSMutableArray array];
    for(NSString *key in [pairs allKeys]) {
        [queries addObject:[NSString stringWithFormat:@"%@  %@",key,[pairs objectForKey:key]]];
    }
    
    return [queries componentsJoinedByString:@"\n"];
}


- (void)dealloc {
    [_tokenKey release];
    [_tokenSecret release];
    [_verify release];
    [_callbackUrl release];
    [_username release];
    [_identifier release];
    [super dealloc];
}

@end
