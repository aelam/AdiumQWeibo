//
//  AIQWeiboAccountViewController.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AIQWeiboAccountViewController.h"

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


- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];

}

- (void)saveConfiguration
{
	[super saveConfiguration];

}

@end
