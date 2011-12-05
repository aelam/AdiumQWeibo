//
//  AIQWeiboAccount.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AIQWeiboAccount.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIChat.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AISharedAdium.h>


@implementation AIQWeiboAccount

- (void)initAccount {
    [super initAccount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatDidOpen:) 
                                                 name:Chat_DidOpen
                                               object:nil];
	
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:QWEIBO_UPDATE_INTERVAL_MINUTES], QWEIBO_PREFERENCE_UPDATE_INTERVAL,
												  [NSNumber numberWithBool:YES], QWEIBO_PREFERENCE_UPDATE_AFTER_SEND,
												  [NSNumber numberWithBool:YES], QWEIBO_PREFERENCE_LOAD_CONTACTS, nil]
										forGroup:QWEIBO_PREFERENCE_GROUP_UPDATES
										  object:self];

    [[adium.preferenceController registerDefaults:[NSNumber numberWithInt:QWEIBO_UPDATE_INTERVAL_MINUTES] forClass:[self class]]
                                        forGroup:PREF_GROUP_FORMATTING];		


}

- (NSString *)defaultServer
{
	return @"t.qq.com";
}

- (void)connect
{
	[super connect];
}

- (void)didConnect
{
	[super didConnect];
	
}

- (void)disconnect
{
	[super disconnect];
	[self didDisconnect];
}

- (void)willBeDeleted
{
	[super willBeDeleted];
}


/*!
 * @brief API path
 *
 * The API path extension for the given host.
 */
- (NSString *)apiPath
{
	return nil;
}

/*!
 * @brief Our source token
 *
 * On Twitter, our given source token is "adiumofficial".
 */
- (NSString *)sourceToken
{
	return @"adiumunofficial";
}



- (void)dealloc {
    [_engine release];
    [super dealloc];
}

@end
