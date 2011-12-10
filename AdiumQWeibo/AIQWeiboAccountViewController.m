//
//  AIQWeiboAccountViewController.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AIQWeiboAccountViewController.h"
#import <Adium/AIAccount.h>

@implementation AIQWeiboAccountViewController

/*!
 * @brief We have no privacy settings.
 */
- (NSView *)privacyView
{
	return nil;
}

/*!
 * @brief Use the Twitter account view.
 */
- (NSString *)nibName
{
    return @"AIQWeiboAccountView";
}

- (void)awakeFromNib {
    NSLog(@"%s LINE %d,%s",__FILE__,__LINE__,__func__);
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
    
    //    [checkBox_updateGlobalStatus setState:[[account preferenceForKey:@"KEY_FETION_USE_MOBILE_ONLINE" 
    //                                                            group:GROUP_ACCOUNT_STATUS] boolValue]];
    
}

- (void)saveConfiguration
{
	[super saveConfiguration];
    //	[account setPreference:[NSNumber numberWithBool:[checkBox_updateGlobalStatus state]] 
    //					forKey:@"KEY_FETION_USE_MOBILE_ONLINE" group:GROUP_ACCOUNT_STATUS];
    
}

@end
