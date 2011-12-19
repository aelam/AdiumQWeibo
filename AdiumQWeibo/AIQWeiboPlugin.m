//
//  AIQWeiboPlugin.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-7.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AIQWeiboPlugin.h"
#import "AIQWeiboService.h"
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>

@implementation AIQWeiboPlugin

- (void)installPlugin
{
    
    NSString *logPath = @"/Users/ryan/Desktop/adium.log";
    [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];    
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    
    
    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
	[AIQWeiboService registerService];        
}

- (NSString *)pluginAuthor {
    return @"Ryan Wang";
}

- (NSString *)pluginVersion {
    return @"0.1";
}

- (NSString *)pluginDescription {
    return @"QQ MiniBlog";
}

- (NSString *)pluginURL {
    return @"https://github.com/aelam/AdiumQWeibo";
}

- (void)dealloc
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[super dealloc];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet *returnSet = nil;
    
	if (!inModifiedKeys) {
		if (([inObject.UID isEqualToString:@"twitter@twitter.com"] &&
			 [inObject.service.serviceClass isEqualToString:@"Jabber"]) ||
			([inObject.service.serviceClass isEqualToString:@"Twitter"] || 
			 [inObject.service.serviceClass isEqualToString:@"Laconica"])) {
                
                if (![inObject valueForProperty:@"Character Counter Max"]) {
                    [inObject setValue:[NSNumber numberWithInteger:140] forProperty:@"Character Counter Max" notify:YES];
                    returnSet = [NSSet setWithObjects:@"Character Counter Max", nil];
                }
            }
	}
	
	return returnSet;
}

@end
