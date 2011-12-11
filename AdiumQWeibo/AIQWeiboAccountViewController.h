//
//  AIQWeiboAccountViewController.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccountViewController.h>
#import "QWeibo.h"

@interface AIQWeiboAccountViewController : AIAccountViewController {
    // Setup - OAuth
	IBOutlet	NSTabView		*tabView_authenticationType;
	IBOutlet	NSTabViewItem	*tabViewItem_basicAuthentication;
	IBOutlet	NSTabViewItem	*tabViewItem_OAuth;
	IBOutlet	NSProgressIndicator *progressIndicator;
	
	IBOutlet	NSTextField		*textField_OAuthStatus;
	IBOutlet	NSTextField		*textField_OAuthVerifier;
	IBOutlet	NSButton		*button_OAuthStart;
	
	// Options
	
	IBOutlet	NSTextField		*textField_APIpath;
	IBOutlet	NSButton		*checkBox_useSSL;
	
	IBOutlet	NSButton		*checkBox_retweet;
	IBOutlet	NSButton		*checkBox_loadContacts;
	
	IBOutlet	NSPopUpButton	*popUp_updateInterval;
	IBOutlet	NSButton		*checkBox_updateAfterSend;
	
	IBOutlet	NSButton		*checkBox_updateGlobalStatus;
	IBOutlet	NSButton		*checkBox_updateGlobalIncludeReplies;
	
	// Personal
	
	IBOutlet	NSTextField		*textField_name;
	IBOutlet	NSTextField		*textField_url;
	IBOutlet	NSTextField		*textField_location;
	IBOutlet	NSTextField		*textField_description;
    
    WeiboEngine  *_authorizeEngine;

}

@end
