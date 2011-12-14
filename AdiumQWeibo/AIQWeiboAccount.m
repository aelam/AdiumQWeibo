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
#import <AIUtilities/AIStringUtilities.h>
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
#import <Adium/AIAdiumProtocol.h>

#import "NSDictionary+Response.h"
#import <Adium/AIControllerProtocol.h>
#import "AdiumQWeiboEngine.h"

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
    
    
    if (!self.host && self.defaultServer) {
		[self setPreference:self.defaultServer forKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
	}
    
	[adium.preferenceController registerPreferenceObserver:self forGroup:QWEIBO_PREFERENCE_GROUP_UPDATES];
	[adium.preferenceController informObserversOfChangedKey:nil inGroup:QWEIBO_PREFERENCE_GROUP_UPDATES object:self];
    
}

- (NSString *)defaultServer
{
	return @"open.t.qq.com";
}

- (void)connect
{
	[super connect];
    
    NIF_TRACE(@"passwordWhileConnected : %@",self.passwordWhileConnected);
    if (self.passwordWhileConnected.length) {        
        NSDictionary *pairs = [NSDictionary oauthTokenPairsFromResponse:self.passwordWhileConnected];
        self.session.tokenKey = [pairs objectForKey:@"oauth_token"];
        self.session.tokenSecret = [pairs objectForKey:@"oauth_token_secret"];
        self.session.username = [pairs objectForKey:@"name"];
        self.session.isValid = YES;

        NIF_TRACE(@"authorize success");
        
        NIF_INFO(@"UID: %@", self.UID);
        

    } else {
        [self setLastDisconnectionError:QWEIBO_OAUTH_NOT_AUTHORIZED];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AIEditAccount"
                                                            object:self];
        [self didDisconnect];

        NIF_TRACE(@"self.passwordWhileConnected.length == 0");
        
        NIF_INFO(@"UID: %@", self.UID);        
    }
    
    [AdiumQWeiboEngine fetchUserInfoWithSession:self.session resultHandler:^(NSDictionary *json, NSHTTPURLResponse *urlResponse, NSError *error) {        
        if (error) {
            NIF_INFO(@"%@", error);
            [self didDisconnect];
        } else {
            NSString *name = [json valueForKeyPath:@"data.name"];
            NSString *nick = [json valueForKeyPath:@"data.nick"];
            NSString *link = [NSString stringWithFormat:@"%@/%@",QWEIBO_WEBPAGE,self.UID];
            NSString *location = [json valueForKeyPath:@"data.location"];
            
            if (name) {
                [self setPreference:[[NSAttributedString stringWithString:name] dataRepresentation]
                             forKey:KEY_ACCOUNT_DISPLAY_NAME
                              group:GROUP_ACCOUNT_STATUS];		
            }
                        
            [self setValue:nick forProperty:@"Profile Name" notify:NotifyLater];
            [self setValue:link forProperty:@"Profile URL" notify:NotifyLater];
            [self setValue:location forProperty:@"Profile Location" notify:NotifyLater];
            [self notifyOfChangedPropertiesSilently:NO];
            
            [self didConnect];
        }
    }];
    
    
}

- (void)didConnect
{
	[super didConnect];
    [self setLastDisconnectionError:nil];
	// Creating the fake timeline account.
    
    NIF_INFO(@"timelineChatName: %@", self.timelineChatName);
	AIListBookmark *timelineBookmark = [adium.contactController existingBookmarkForChatName:self.timelineChatName
																				  onAccount:self
																		   chatCreationInfo:nil];
    NIF_INFO(@"timelineChatName: %@", timelineBookmark);
	if(!timelineBookmark) {
		AIChat *newTimelineChat = [adium.chatController chatWithName:self.timelineChatName
														  identifier:nil
														   onAccount:self 
													chatCreationInfo:nil];
		
		[newTimelineChat setDisplayName:self.timelineChatName];
        NIF_INFO(@"timelineChatName: %@", timelineBookmark);
        if(!timelineBookmark) {
//            NSLog(@"%@ Timeline bookmark is nil! Tried checking for existing bookmark for chat name %@, and creating a bookmark for chat %@ in group %@", self.timelineChatName, newTimelineChat, [adium.contactController groupWithUID:QWEIBO_REMOTE_GROUP_NAME]);
        }            
    }
    
    NSTimeInterval updateInterval = [[self preferenceForKey:QWEIBO_PREFERENCE_UPDATE_INTERVAL group:QWEIBO_PREFERENCE_GROUP_UPDATES] integerValue] * 60;

    if(updateInterval > 0) {
		[updateTimer invalidate];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
													   target:self
													 selector:@selector(periodicUpdate)
													 userInfo:nil
													  repeats:YES];
		
		[self periodicUpdate];
	}

}

- (void)disconnect
{
	[super disconnect];
    NIF_TRACE();
    [updateTimer invalidate]; updateTimer = nil;
    
    [self didDisconnect];

}

- (void)willBeDeleted
{
	[super willBeDeleted];
}

- (void)didDisconnect
{    
	[super didDisconnect];
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

- (BOOL)encrypted
{
    return self.online;
}


/*!
 * @brief Affirm we can open chats.
 */
- (BOOL)openChat:(AIChat *)chat
{	
	[chat setValue:[NSNumber numberWithBool:YES] forProperty:@"Account Joined" notify:NotifyNow];
	
	return YES;
}

/*!
 * @brief Allow all chats to close.
 */
- (BOOL)closeChat:(AIChat *)inChat
{	
	return YES;
}

/*!
 * @brief Rejoin the requested chat.
 */
- (BOOL)rejoinChat:(AIChat *)inChat
{	
	[self displayYouHaveConnectedInChat:inChat];
	
	return YES;
}

/*!
 * @brief We always want to autocomplete the UID.
 */
- (BOOL)chatShouldAutocompleteUID:(AIChat *)inChat
{
	return YES;
}

/*!
 * @brief A chat opened.
 *
 * If this is a group chat which belongs to us, aka a timeline chat, set it up how we want it.
 */
- (void)chatDidOpen:(NSNotification *)notification
{
	AIChat *chat = [notification object];
	
	if(chat.isGroupChat && chat.account == self) {
        //		[self updateTimelineChat:chat];
        NIF_INFO();
	}	
}

/*!
 * @brief We support adding and removing follows.
 */
- (BOOL)contactListEditable
{
    return self.online;
}

/*!
 * @brief Move contacts
 *
 * Move existing contacts to a specific group on this account.  The passed contacts should already exist somewhere on
 * this account.
 * @param objects NSArray of AIListContact objects to remove
 * @param group AIListGroup destination for contacts
 */
- (void)moveListObjects:(NSArray *)objects oldGroups:(NSSet *)oldGroups toGroups:(NSSet *)groups
{
	// XXX do twitter grouping
}

/*!
 * @brief Rename a group
 *
 * Rename a group on this account.
 * @param group AIListGroup to rename
 * @param newName NSString name for the group
 */
- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName
{
	// XXX do twitter grouping
}

/*!
 * @brief For an invalid password, fail but don't try and reconnect or report it. We do it ourself.
 */
- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	AIReconnectDelayType reconnectDelayType = [super shouldAttemptReconnectAfterDisconnectionError:disconnectionError];
	
    //	if ([*disconnectionError isEqualToString:TWITTER_INCORRECT_PASSWORD_MESSAGE]) {
    //		reconnectDelayType = AIReconnectImmediately;
    //	} else if ([*disconnectionError isEqualToString:TWITTER_OAUTH_NOT_AUTHORIZED]) {
    //		reconnectDelayType = AIReconnectNeverNoMessage;
    //	}
	
	return reconnectDelayType;
}

/*!
 * @brief Don't allow OTR encryption.
 */
- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat
{
	return NO;
}


/*!
 * @brief Update our status
 */
- (void)setSocialNetworkingStatusMessage:(NSAttributedString *)statusMessage
{
    //	NSString *requestID = [twitterEngine sendUpdate:[statusMessage string]];
    //    
    //	if(requestID) {
    //		[self setRequestType:AITwitterSendUpdate
    //				forRequestID:requestID
    //			  withDictionary:nil];
    //	}
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [[inAttributedString attributedStringByConvertingLinksToURLStrings] string];
}

/////////////////////
/////////////////////

#pragma mark OAuth
/*!
 * @brief Should we store our password based on internal object ID?
 *
 * We only need to if we're using OAuth.
 */
- (BOOL)useInternalObjectIDForPasswordName
{
    return self.useOAuth;
}

/*!
 * @brief Should we connect using OAuth?
 *
 * If enabled, the account view will display the OAuth setup. Basic authentication will not be used.
 */
- (BOOL)useOAuth
{
	return YES;
}

/*!
 * @brief Last disconnection error
 */
- (NSString *)lastDisconnectionError
{
	return lastDisconnectionError;
}

/*!
 * @brief Set the last disconnection error
 */
- (void)setLastDisconnectionError:(NSString *)inError
{
    // If we already have an error, ignore the new one, unless
    // we're resetting to nil.
    if (lastDisconnectionError && inError) {
        return;
    }
    
	if (lastDisconnectionError != inError) {
		[lastDisconnectionError release];
		lastDisconnectionError = [inError retain];
	}
}

/*!
 * @brief Update the timeline chat
 * 
 * Remove the userlist
 */
- (void)updateTimelineChat:(AIChat *)timelineChat
{
	// Disable the user list on the chat.
	if (timelineChat.chatContainer.chatViewController.userListVisible) {
		[timelineChat.chatContainer.chatViewController toggleUserList]; 
	}	
	
	// Update the participant list.
	[timelineChat addParticipatingListObjects:self.contacts notify:NotifyNow];
	
	[timelineChat setValue:[NSNumber numberWithInt:140] forProperty:@"Character Counter Max" notify:NotifyNow];
}


/*!
 * @brief Update serverside icon
 *
 * This is called by AIUserIcons when it needs an icon update for a contact.
 * If we already have an icon set (even a cached icon), ignore it.
 * Otherwise return the Twitter service icon.
 *
 * This is so that when an unknown contact appears, it has an actual image
 * to replace in the WKMV when an actual icon update is returned.
 *
 * This service icon will not remain saved very long, I see no harm in using it.
 * This only occurs for "strangers".
 */
- (NSData *)serversideIconDataForContact:(AIListContact *)listContact
{
	if (![AIUserIcons userIconSourceForObject:listContact] &&
		![AIUserIcons cachedUserIconExistsForObject:listContact]) {
		return [[self.service defaultServiceIconOfType:AIServiceIconLarge] TIFFRepresentation];
	} else {
		return nil;
	}
}

/*!
 * @brief Update a user icon from a URL if necessary
 */
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;
{
	// If we don't already have an icon for the user...
	if(![[listContact valueForProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON] boolValue]) {
		NSString *fileName = [[url lastPathComponent] stringByReplacingOccurrencesOfString:@"_normal." withString:@"_bigger."];
		
		url = [[url stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
		
		// Grab the user icon and set it as their serverside icon.
//		NSString *requestID = [twitterEngine getImageAtURL:url];
		
//		if(requestID) {
//			[self setRequestType:AITwitterUserIconPull
//					forRequestID:requestID
//				  withDictionary:[NSDictionary dictionaryWithObject:listContact forKey:@"ListContact"]];
//		}
		
		[listContact setValue:[NSNumber numberWithBool:YES] forProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
	}
}

#warning REMOVE
/*!
 * @brief Unfollow the requested contacts.
 */
- (void)removeContacts:(NSArray *)objects fromGroups:(NSArray *)groups
{	
	for (AIListContact *object in objects) {
//		NSString *requestID = [twitterEngine disableUpdatesFor:object.UID];
		
//		AILogWithSignature(@"%@ Requesting unfollow for: %@", self, object.UID);
		
//		if(requestID) {
//			[self setRequestType:AITwitterRemoveFollow
//					forRequestID:requestID
//				  withDictionary:[NSDictionary dictionaryWithObject:object forKey:@"ListContact"]];
//		}	
	}
}

/*!
 * @brief Follow the requested contact, trigger an information pull for them.
 */
- (void)addContact:(AIListContact *)contact toGroup:(AIListGroup *)group
{
    NIF_INFO(@"%@", contact);
    NIF_INFO(@"%@", group);
	if ([contact.UID isCaseInsensitivelyEqualToString:self.UID]) {
//		AILogWithSignature(@"Not adding contact %@ to group %@, it's me!", contact.UID, group.UID);
		return;
	}
	
//	NSString	*requestID = [twitterEngine enableUpdatesFor:contact.UID];
//	
//	AILogWithSignature(@"%@ Requesting follow for: %@", self, contact.UID);
//	
//	if(requestID) {	
//		NSString	*updateRequestID = [twitterEngine getUserInformationFor:contact.UID];
//		
//		if (updateRequestID) {
//			[self setRequestType:AITwitterAddFollow
//					forRequestID:updateRequestID
//				  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:contact.UID, @"UID", nil]];
//		}
//	}
}


#pragma mark Preference updating
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
    NIF_INFO(@"%@", group);
    NIF_INFO(@"%@", key);
    NIF_INFO(@"%@", prefDict);
    
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
    NIF_INFO(@"");
	// We only care about our changes.
	if (object != self) {
		return;
	}
	
	if([group isEqualToString:GROUP_ACCOUNT_STATUS]) {
		if([key isEqualToString:KEY_USER_ICON]) {
			// Avoid pushing an icon update which we just downloaded.
			if(![self boolValueForProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON]) {
//				NSString *requestID = [twitterEngine updateProfileImage:[prefDict objectForKey:KEY_USER_ICON]];
                
//				if(requestID) {
//					AILogWithSignature(@"%@ Pushing self icon update", self);
//					
//					[self setRequestType:AITwitterProfileSelf
//							forRequestID:requestID
//						  withDictionary:nil];
//				}
			}
			
			[self setValue:nil forProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
		}
	}
	
	if([group isEqualToString:QWEIBO_PREFERENCE_GROUP_UPDATES]) {
		if(!firstTime && [key isEqualToString:QWEIBO_PREFERENCE_UPDATE_INTERVAL]) {
			NSTimeInterval timeInterval = [updateTimer timeInterval];
			NSTimeInterval newTimeInterval = [[prefDict objectForKey:QWEIBO_PREFERENCE_UPDATE_INTERVAL] intValue] * 60;
			
			if (timeInterval != newTimeInterval && self.online) {
				[updateTimer invalidate]; updateTimer = nil;
				
				if(newTimeInterval > 0) {
					updateTimer = [NSTimer scheduledTimerWithTimeInterval:newTimeInterval
																   target:self
																 selector:@selector(periodicUpdate)
																 userInfo:nil
																  repeats:YES];
				}
			}
		}
		
//		updateAfterSend = [[prefDict objectForKey:QWEIBO_PREFERENCE_UPDATE_AFTER_SEND] boolValue];
//		retweetLink = [[prefDict objectForKey:QWEIBO_PREFERENCE_RETWEET_SPAM] boolValue];
		
		if ([key isEqualToString:QWEIBO_PREFERENCE_LOAD_CONTACTS] && self.online) {
			if ([[prefDict objectForKey:QWEIBO_PREFERENCE_LOAD_CONTACTS] boolValue]) {
				// Delay updates when loading our contacts list.
				[self silenceAllContactUpdatesForInterval:18.0];
				// Grab our user list.
//				NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:1];
				
//				if (requestID) {
//					[self setRequestType:AITwitterInitialUserInfo
//							forRequestID:requestID
//						  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"Page"]];
//				}
                NIF_INFO(@"fan list");
                [AdiumQWeiboEngine fetchUsersListWithSession:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                    NIF_INFO(@"fan list : %@", responseJSON);
                }];
                
                
			} else {
				[self removeAllContacts];
			}
		}
	}	
}


#pragma mark Contact handling
/*!
 * @brief The name of our timeline chat
 */
- (NSString *)timelineChatName
{
	return [NSString stringWithFormat:QWEIBO_TIMELINE_NAME, self.UID];
}

/*!
 * @brief Our timeline chat
 *
 * If the timeline chat is not already active, it is created.
 */
- (AIChat *)timelineChat
{
	AIChat *timelineChat = [adium.chatController existingChatWithName:self.timelineChatName
                                                            onAccount:self];
	
	if (!timelineChat) {
		timelineChat = [adium.chatController chatWithName:self.timelineChatName
                                               identifier:nil
                                                onAccount:self
                                         chatCreationInfo:nil];
	}
    
	return timelineChat;	
}

- (void)periodicUpdate {
    
}

- (QOAuthSession *)session {
    if (_session == nil) {
        _session = [[QOAuthSession alloc] initWithIdentifier:self.internalObjectID];
    }
    return _session;
}


#pragma mark Message Display
/*!
 * @brief Returns a user-readable message for an error code.
 */
- (NSString *)errorMessageForError:(NSError *)error
{
	switch (error.code) {
		case 400:
			// Bad Request: your request is invalid, and we'll return an error message that tells you why.
			// This is the status code returned if you've exceeded the rate limit. 
			return AILocalizedString(@"You've exceeded the rate limit.", nil);
			break;
			
		case 401:
			// Not Authorized: either you need to provide authentication credentials, or the credentials provided aren't valid.
			return AILocalizedString(@"Your credentials do not allow you access.", nil);
			break;
			
		case 403:
			// Forbidden: we understand your request, but are refusing to fulfill it.  An accompanying error message should explain why.
			return AILocalizedString(@"Request refused by the server.", nil);
			break;
			
		case 404:
			// Not Found: either you're requesting an invalid URI or the resource in question doesn't exist (ex: no such user). 
			return AILocalizedString(@"Requested resource not found.", nil);
			break;
			
		case 500:
			// Internal Server Error: we did something wrong.  Please post to the group about it and the Twitter team will investigate.
			return AILocalizedString(@"The server reported an internal error.", nil);
			break;
			
		case 502:
			// Bad Gateway: returned if Twitter is down or being upgraded.
			return AILocalizedString(@"The server is currently down.", nil);
			break;
			
		case -1001:
			// Timeout
		case 503:
			// Service Unavailable: the Twitter servers are up, but are overloaded with requests.  Try again later.
			return AILocalizedString(@"The server is overloaded with requests.", nil);
			break;
			
	}
	
	return [NSString stringWithFormat:AILocalizedString(@"Unknown error: code %d, %@", nil), error.code, error.localizedDescription];
}


- (void)_updateProfileWithInfo:(NSDictionary *)json {
    
}


- (void)dealloc {
    [_session release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
    
    [super dealloc];
}

@end
