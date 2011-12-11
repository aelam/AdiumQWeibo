//
//  AIQWeiboAccountViewController.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AIQWeiboAccountViewController.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIStringUtilities.h>
#import "WeiboEngine.h"
#import "AIQWeiboAccount.h"
#import <Adium/AISharedAdium.h>
#import <Adium/AIAdiumProtocol.h>
#import <Adium/AIControllerProtocol.h>

#define BUTTON_TEXT_ALLOW_ACCESS		AILocalizedString(@"Allow Adium access", nil)

@interface AIQWeiboAccountViewController (Private)

- (void)setStatusText:(NSString *)text withColor:(NSColor *)color buttonEnabled:(BOOL)enabled buttonText:(NSString *)buttonText;

@end

@implementation AIQWeiboAccountViewController

/*!
 * @brief We have no privacy settings.
 */
- (NSView *)privacyView
{
	return nil;
}

/*!
 * @brief Use the QWEIBO account view.
 */
- (NSString *)nibName
{
    return @"AIQWeiboAccountView";
}

- (void)awakeFromNib {

}

- (void)configureForAccount:(AIQWeiboAccount *)inAccount
{
	[super configureForAccount:inAccount];
    
    NSLog(@"- - ----------  -- - - - - %@",[inAccount passwordWhileConnected]);
    NIF_INFO(@"----- %d",[inAccount shouldBeOnline]);
    
		if ([account.lastDisconnectionError isEqualToString:QWEIBO_OAUTH_NOT_AUTHORIZED]) {
			[self setStatusText:QWEIBO_OAUTH_NOT_AUTHORIZED
					  withColor:[NSColor redColor]
				  buttonEnabled:YES
					 buttonText:BUTTON_TEXT_ALLOW_ACCESS];
            
		} else if (account.UID && [[adium.accountController passwordForAccount:account] length]) {
			[self setStatusText:AILocalizedString(@"Adium currently has access to your account.", nil)
					  withColor:nil
				  buttonEnabled:NO
					 buttonText:BUTTON_TEXT_ALLOW_ACCESS];
		} else {
			[self setStatusText:nil
					  withColor:nil
				  buttonEnabled:YES
					 buttonText:BUTTON_TEXT_ALLOW_ACCESS];
		}
    
    [textField_OAuthVerifier setHidden:YES];

    if (account.online) {
        
        NIF_TRACE(@"account is online");
        textField_name.stringValue = @"test";//[account valueForProperty:@"Profile Name"] ?: @"";
        textField_url.stringValue =  @"test";//[account valueForProperty:@"Profile URL"] ?: @"";
        textField_location.stringValue =  @"test";//[account valueForProperty:@"Profile Location"] ?: @"";
        textField_description.stringValue =  @"test";//[account valueForProperty:@"Profile Description"] ?: @"";
        
        [textField_name setEnabled:account.online];
        [textField_url setEnabled:account.online];
        [textField_location setEnabled:account.online];
        [textField_description setEnabled:account.online];
        
        textField_APIpath.stringValue = @"";
        
        [textField_connectHost setEnabled:NO];
        [textField_APIpath setEnabled:NO];
        [checkBox_useSSL setEnabled:NO];
        
    }
}

- (void)saveConfiguration
{
	[super saveConfiguration];
    
	[account setPreference:popUp_updateInterval.selectedItem.representedObject
					forKey:QWEIBO_PREFERENCE_UPDATE_INTERVAL
					 group:QWEIBO_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_updateAfterSend state]]
					forKey:QWEIBO_PREFERENCE_UPDATE_AFTER_SEND
					 group:QWEIBO_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_updateGlobalStatus state]]
					forKey:QWEIBO_PREFERENCE_UPDATE_GLOBAL
					 group:QWEIBO_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_updateGlobalIncludeReplies state]]
					forKey:QWEIBO_PREFERENCE_UPDATE_GLOBAL_REPLIES
					 group:QWEIBO_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_retweet state]]
					forKey:QWEIBO_PREFERENCE_RETWEET_SPAM
					 group:QWEIBO_PREFERENCE_GROUP_UPDATES];
    
	[account setPreference:[NSNumber numberWithBool:[checkBox_loadContacts state]]
					forKey:QWEIBO_PREFERENCE_LOAD_CONTACTS
					 group:QWEIBO_PREFERENCE_GROUP_UPDATES];
	

}

- (IBAction)changedPreference:(id)sender {
    if (sender == button_OAuthStart) {
        [textField_OAuthVerifier setHidden:YES];
        [progressIndicator setHidden:NO];
        [progressIndicator startAnimation:nil];
        
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
        
        [_authorizeEngine release];
        _authorizeEngine = [[WeiboEngine alloc] initWithURL:nil parameters:nil requestMethod:RequestMethodGET];
        [_authorizeEngine authorizeWithBlock:^(NSString *desc, BOOL sucess) {
            NSLog(@"%s %d",__func__,__LINE__);
            NSLog(@"sucess?:%d",sucess);
            NSLog(@"%@",desc);

            if (sucess) {
                
                [self setStatusText:AILocalizedString(@"Success! Adium now has access to your account. Click OK below.", nil)
                          withColor:nil
                      buttonEnabled:NO
                         buttonText:nil];
                
                [textField_OAuthVerifier setHidden:YES];
                [progressIndicator setHidden:YES];
                [progressIndicator stopAnimation:nil];
                
                textField_password.stringValue = desc;
                [account setLastDisconnectionError:nil];
                [account setValue:[NSNumber numberWithBool:YES] forProperty:@"Reconnect After Edit" notify:NotifyNever];
                
                [account setValue:[NSNumber numberWithBool:YES] forProperty:@"Online" notify:NotifyNever];

                NIF_INFO(@"isOnline? %u", account.online);
                
            } else {
                [self setStatusText:AILocalizedString(@"An error occured while trying to gain access. Please try again.", nil)
                          withColor:[NSColor redColor]
                      buttonEnabled:YES
                         buttonText:BUTTON_TEXT_ALLOW_ACCESS];
                
                [textField_OAuthVerifier setHidden:YES];
                [progressIndicator setHidden:YES];
                [progressIndicator stopAnimation:nil];
            }
        }];
        
    }    
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    [_authorizeEngine handleOpenURL:[NSURL URLWithString:url]];
}

#pragma mark OAuth status text
- (void)setStatusText:(NSString *)text withColor:(NSColor *)color buttonEnabled:(BOOL)enabled buttonText:(NSString *)buttonText
{
	textField_OAuthStatus.stringValue = text ?: @"";
	textField_OAuthStatus.textColor = color ?: [NSColor controlTextColor];
    
	[button_OAuthStart setEnabled:enabled];
	
	if(buttonText) {
		button_OAuthStart.title = buttonText;
		[button_OAuthStart sizeToFit];
		[button_OAuthStart setFrameOrigin:NSMakePoint(NSMidX(button_OAuthStart.superview.frame) - NSWidth(button_OAuthStart.frame)/2.0f,
													  NSMinY(button_OAuthStart.frame))];
	}
}


@end
