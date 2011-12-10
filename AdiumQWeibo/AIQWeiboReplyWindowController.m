//
//  AIQWeiboReplyWindowController.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AIQWeiboReplyWindowController.h"
//#import "AIURLHandlerPlugin.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AIQWeiboAccount.h"

@implementation AIQWeiboReplyWindowController

@synthesize account;

static AIQWeiboReplyWindowController *sharedController = nil;

+ (void)showReplyWindowForAccount:(AIAccount *)inAccount
{
	if (!sharedController) {
		sharedController = [[self alloc] initWithWindowNibName:@"AITwitterReplyWindow"];
	}
	
	// Make sure the window has loaded
	[sharedController window];
	
	sharedController.account = inAccount;
	
	[sharedController showWindow:nil];
	[sharedController.window makeKeyAndOrderFront:nil];
}

- (void)windowDidLoad
{
//	[label_statusID setLocalizedString:AILocalizedString(@"Status ID:", "In the 'reply to tweet' window, this is the field for the ID of the status (numerical).")];
//	[label_usernameOrTweetURL setLocalizedString:AILocalizedString(@"Username or Tweet URL:", "Either the username or the URL of a tweet we want to reply to.")];
//	
//	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];
//	[button_reply setLocalizedString:AILocalizedString(@"Reply", nil)];
//	
//	[self.window setTitle:AILocalizedString(@"Reply to a Tweet", "Name of the 'reply to a tweet' window.")];
	
	[super windowDidLoad];
}


- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[sharedController autorelease]; sharedController = nil;
}

/*!
 * @brief Broadcast a "reply to this" message.
 */
- (IBAction)reply:(id)sender
{
	if (([textField_usernameOrTweetURL.stringValue rangeOfCharacterFromSet:[account.service.allowedCharacters invertedSet]].location != NSNotFound) ||
		(![[NSString stringWithFormat:@"%qu", [textField_statusID.stringValue unsignedLongLongValue]] isEqualToString:textField_statusID.stringValue])) {
		NSBeep();
	} else if (textField_usernameOrTweetURL.stringValue && textField_statusID.stringValue) {
        
//		NSString *replyAddress = [(AIQWeiboAccount *)account addressForLinkType:AITwitterLinkReply
//																		  userID:textField_usernameOrTweetURL.stringValue
//																		statusID:textField_statusID.stringValue
//																		 context:nil];
//		[[NSNotificationCenter defaultCenter] postNotificationName:AIURLHandleNotification object:replyAddress];
		
//		[self closeWindow:nil];
	}
}

/*!
 * @brief Cancel.
 */
- (IBAction)cancel:(id)sender
{	
	[self closeWindow:nil];
}

/*!
 * @brief Detect a twitter.com URL being pasted in.
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *textField = [notification object];
	
	if (textField == textField_usernameOrTweetURL) {
		NSString *value = [textField stringValue];
		NSRange	 twitterLocation = [value rangeOfString:@"twitter.com"];
		
		if (twitterLocation.location != NSNotFound) {			
			NSArray *components = [[value substringFromIndex:twitterLocation.location] pathComponents];
            
			if (components.count == 4 && ([[components objectAtIndex:2] isEqualToString:@"status"] ||
										  [[components objectAtIndex:2] isEqualToString:@"statuses"])) {
				textField_usernameOrTweetURL.stringValue = [components objectAtIndex:1];
				textField_statusID.stringValue = [components objectAtIndex:3];
			}
		}
	}
}

- (void)dealloc
{
	[account release];
    
	[super dealloc];
}

@end
