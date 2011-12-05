//
//  AdiumQWeibo.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AdiumQWeiboPlugin.h"
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/AIContactObserverManager.h>
#import "AIQWeiboService.h"

@implementation AdiumQWeiboPlugin

- (void)installPlugin
{
//    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
    [AIQWeiboService registerService];

}

- (void)uninstallPlugin
{
    [[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
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
