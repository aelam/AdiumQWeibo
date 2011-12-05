//
//  AIQWeiboReplyWindowController.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIWindowController.h>
#import <Adium/AIAccount.h>

@interface AIQWeiboReplyWindowController : AIWindowController {
    IBOutlet NSTextField			*label_usernameOrTweetURL;
	IBOutlet NSTextField			*textField_usernameOrTweetURL;
	
	IBOutlet NSTextField			*label_statusID;
	IBOutlet NSTextField			*textField_statusID;
	
	IBOutlet NSButton				*button_reply;
	IBOutlet NSButton				*button_cancel;

    AIAccount	*account;
}

+ (void)showReplyWindowForAccount:(AIAccount *)inAccount;

- (IBAction)reply:(id)sender;
- (IBAction)cancel:(id)sender;

@property (nonatomic, retain) AIAccount *account;

@end
