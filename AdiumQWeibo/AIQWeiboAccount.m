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
#import "AdiumQWeiboEngine+Helper.h"


@interface AIQWeiboAccount (Private)

- (void)_fetchImageWithURL:(NSString *)url imageHander:(void(^)(NSImage *image))imageHander;
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;
- (NSString *)addressForLinkType:(AIQWeiboLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context;
@end

@implementation AIQWeiboAccount

- (void)initAccount {
    [super initAccount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatDidOpen:) 
                                                 name:Chat_DidOpen
                                               object:nil];
	
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:QWEIBO_UPDATE_INTERVAL_MINUTES],QWEIBO_PREFERENCE_UPDATE_INTERVAL,
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
    
    if (self.passwordWhileConnected.length) {        
        NSDictionary *pairs = [NSDictionary oauthTokenPairsFromResponse:self.passwordWhileConnected];
        self.session.tokenKey = [pairs objectForKey:@"oauth_token"];
        self.session.tokenSecret = [pairs objectForKey:@"oauth_token_secret"];
        self.session.username = [pairs objectForKey:@"name"];
        self.session.isValid = YES;

        NIF_TRACE(@"authorize success UID: %@", self.UID);                

    } else {
        [self setLastDisconnectionError:QWEIBO_OAUTH_NOT_AUTHORIZED];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AIEditAccount"
                                                            object:self];
        [self didDisconnect];

    }
    
    [AdiumQWeiboEngine fetchUserInfoWithSession:self.session resultHandler:^(NSDictionary *json, NSHTTPURLResponse *urlResponse, NSError *error) {        
        if (error) {
            NIF_INFO(@"%@", error);
            [self didDisconnect];
        } else {

            // 
            // SET MY INFORMATION
            //
            NSString *name = [json valueForKeyPath:@"data.name"];
            NSString *head = [json valueForKeyPath:@"data.head"];
            NSString *nick = [json valueForKeyPath:@"data.nick"];
            NSString *link = [NSString stringWithFormat:@"%@/%@",QWEIBO_WEBPAGE,self.UID];
            NSString *location = [json valueForKeyPath:@"data.location"];
            
            [self filterAndSetUID:name];
            
            if (nick) {
                [self setPreference:[[NSAttributedString stringWithString:nick] dataRepresentation]
                             forKey:KEY_ACCOUNT_DISPLAY_NAME
                              group:GROUP_ACCOUNT_STATUS];		
            }
                                    
            [self setValue:nick forProperty:@"Profile Name" notify:NotifyLater];
            [self setValue:link forProperty:@"Profile URL" notify:NotifyLater];
            [self setValue:location forProperty:@"Profile Location" notify:NotifyLater];
            [self notifyOfChangedPropertiesSilently:NO];
            
            //
            // grab SELF HEAD icon
            //
            
            NSString *imageURL = [head stringByAppendingFormat:@"/%d",200];

            [self _fetchImageWithURL:imageURL imageHander:^(NSImage *image) {
                [self setValue:[NSNumber numberWithBool:YES] forProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
                
                [self setPreference:[NSNumber numberWithBool:YES]
                             forKey:KEY_USE_USER_ICON
                              group:GROUP_ACCOUNT_STATUS];
                
                
                [self setPreference:[image TIFFRepresentation]
                             forKey:KEY_USER_ICON
                              group:GROUP_ACCOUNT_STATUS];
            }];
                        
			// Our UID is definitely set; grab our friends.
			if ([[self preferenceForKey:QWEIBO_PREFERENCE_LOAD_CONTACTS group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue]) {
				// If we load our follows as contacts, do so now.
				// Delay updates on initial login.
				[self silenceAllContactUpdatesForInterval:18.0];
				// Grab our user list.
                
                [AdiumQWeiboEngine fetchFollowingListFromPage:0 session:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                    
                    if(!self.online || error) {
                        return ;
                    }
                    
                    
                    NSArray *users = [responseJSON valueForKeyPath:@"data.info"];
                    for(NSDictionary *user in users) {
                        
                        AIListContact *listContact = [self contactWithUID:[user objectForKey:QWEIBO_INFO_UID]];

                        // If the user isn't in a group, set them in the Twitter group.
                        if(listContact.countOfRemoteGroupNames == 0) {
                            [listContact addRemoteGroupName:QWEIBO_REMOTE_GROUP_NAME];
                        }
                        
                        // Grab the Twitter display name and set it as the remote alias.
                        if (![[listContact valueForProperty:@"Server Display Name"] isEqualToString:[user objectForKey:QWEIBO_INFO_SCREEN_NAME]]) {
                            [listContact setServersideAlias:[user objectForKey:QWEIBO_INFO_SCREEN_NAME]
                                                   silently:silentAndDelayed];
                        }
                        
                        // Grab the user icon and set it as their serverside icon.
                        [self updateUserIcon:[user objectForKey:QWEIBO_INFO_ICON_URL] forContact:listContact];
                        
                        // Grab the user icon and set it as their serverside icon.
//                        [self updateUserIcon:(NSString *)[user objectForKey:QWEIBO_INFO_ICON_URL] forContact:listContact];
                        
                        // Set the user as available.
                        [listContact setStatusWithName:nil
                                            statusType:AIAvailableStatusType
                                                notify:NotifyLater];
                        
                        // Set the user's status message to their current twitter status text
                        NSArray *tweets = [user valueForKey:QWEIBO_INFO_STATUS];
                        NSString *statusText = @"";
                        if (tweets && [tweets count]) {
                            NSDictionary *tweet = [tweets objectAtIndex:0];
                            statusText = [tweet objectForKey:QWEIBO_INFO_STATUS_TEXT];
                            if (!statusText) //nil if they've never tweeted
                                statusText = @"";

                        } else {
                            
                        }
                        
                        [listContact setStatusMessage:[NSAttributedString stringWithString:[statusText stringByUnescapingFromXMLWithEntities:nil]] notify:NotifyLater];
                        
                        // Set the user as online.
                        [listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];
                        
                        [listContact notifyOfChangedPropertiesSilently:silentAndDelayed];
                    }
                    
                    [[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
                }];                
            }
            
            
            
            
            [self didConnect];
        }
    }];
    
    
}

- (void)didConnect
{
	[super didConnect];
    [self setLastDisconnectionError:nil];
	
    // Creating the fake timeline account.
    
	AIListBookmark *timelineBookmark = [adium.contactController existingBookmarkForChatName:self.timelineChatName
																				  onAccount:self
																		   chatCreationInfo:nil];
	if(!timelineBookmark) {
		AIChat *newTimelineChat = [adium.chatController chatWithName:self.timelineChatName
														  identifier:nil
														   onAccount:self 
													chatCreationInfo:nil];
		
		[newTimelineChat setDisplayName:self.timelineChatName];
        timelineBookmark = [adium.contactController bookmarkForChat:newTimelineChat inGroup:[adium.contactController groupWithUID:QWEIBO_REMOTE_GROUP_NAME]];

        if(!timelineBookmark) {

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
	
    if ([*disconnectionError isEqualToString:QWEIBO_INCORRECT_PASSWORD_MESSAGE]) {
        reconnectDelayType = AIReconnectImmediately;
    } else if ([*disconnectionError isEqualToString:QWEIBO_OAUTH_NOT_AUTHORIZED]) {
        reconnectDelayType = AIReconnectNeverNoMessage;
    }
	
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
    //		[self setRequestType:AIQWeiboSendUpdate
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
/*!
 * @brief Trigger an info update
 *
 * This is called when the info inspector wants more information on a contact.
 * Grab the user's profile information, set everything up accordingly in the user info method.
 */
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
	if(!self.online) {
		return;
	}

    [AdiumQWeiboEngine fetchUserInfoWithUID:inContact.UID session:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (!error) {
            NSDictionary *thisUserInfo = [responseJSON objectForKey:@"data"];
            NIF_TRACE(@"-------------------------- %@", thisUserInfo);

            if (thisUserInfo && [thisUserInfo count]) {

                NSMutableArray *profileArray = [NSMutableArray array];
                NSMutableArray *readableNames = [NSMutableArray array];
                
                // Screen Name
                [readableNames addObject:AILocalizedString(@"Name", nil)];
                NSString *name = [thisUserInfo objectForKey:@"nick"];
                [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         AILocalizedString(@"Name", nil), KEY_KEY, 
                                         name, KEY_VALUE, nil]
                 ];
                
                // Birthday
                NSString *birthday = nil;
                NSNumber *year = [thisUserInfo objectForKey:@"birth_year"];
                NSNumber *month = [thisUserInfo objectForKey:@"birth_month"];
                NSNumber *day = [thisUserInfo objectForKey:@"birth_day"];
                
                if (year && month && day && [year intValue] && [month intValue] && [day intValue]) {
                    birthday = [NSString stringWithFormat:@"%@/%@/%@",year,month,day];

                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Birth", nil), KEY_KEY, 
                                             [NSAttributedString stringWithString:birthday], KEY_VALUE, nil]
                    ];
                }
                
                // Gender 
                BOOL gender = [[thisUserInfo valueForKey:@"sex"]boolValue];
                [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         AILocalizedString(@"Gender", nil), KEY_KEY, 
                                         [NSAttributedString stringWithString:(gender?AILocalizedString(@"Male", nil):AILocalizedString(@"Female", nil))], KEY_VALUE, nil]
                ];
                
                // Email
                NSString *email = [thisUserInfo objectForKey:@"email"];
                if (email && [email length]) {
                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Email", nil), KEY_KEY, 
                                             [NSAttributedString stringWithString:email], KEY_VALUE, nil]
                    ];
                }
                
                // Webpage : unknown

                // Location
                NSString *location = [thisUserInfo objectForKey:@"location"];
                if (location && [location length]) {
                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Location", nil), KEY_KEY, 
                                             [NSAttributedString stringWithString:location], KEY_VALUE, nil]
                     ];
                }
                
                // Followers Link
                NSInteger followers = [[thisUserInfo objectForKey:@"fansnum"] intValue];
                if(followers != 0) {
                    NSString *followersString = [NSString stringWithFormat:@"%d",followers];
                    NSAttributedString *value = [NSAttributedString attributedStringWithLinkLabel:followersString
                                                                                   linkDestination:[AdiumQWeiboEngine addressForLinkType:AIQWeiboLinkFollowers userID:inContact.UID statusID:@"123" context:@"34232423"]]; 
                    
                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Followers", nil), KEY_KEY, 
                                             value, KEY_VALUE, nil]
                     ];
                }
                
                // Following Link
                NSInteger following = [[thisUserInfo objectForKey:@"idolnum"] intValue];
                if(followers != 0) {
                    NSString *followingString = [NSString stringWithFormat:@"%d",following];
                    NSString *address = [AdiumQWeiboEngine addressForLinkType:AIQWeiboLinkFollowings userID:inContact.UID statusID:@"123" context:@"34232423"];
                    NSAttributedString *value = [NSAttributedString attributedStringWithLinkLabel:followingString
                                                                                  linkDestination:address]; 
                    
                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Following", nil), KEY_KEY, 
                                             value, KEY_VALUE, nil]
                     ];
                }
                
                // Tweets
                NSInteger tweets = [[thisUserInfo objectForKey:@"tweetnum"] intValue];
                if(followers != 0) {
                    NSString *tweetsString = [NSString stringWithFormat:@"%d",tweets];
                    NSString *address = [AdiumQWeiboEngine addressForLinkType:AIQWeiboLinkTweetCount userID:inContact.UID statusID:@"123" context:@"34232423"];
                    NSAttributedString *value = [NSAttributedString attributedStringWithLinkLabel:tweetsString
                                                                                  linkDestination:address]; 
                    
                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Tweets", nil), KEY_KEY, 
                                             value, KEY_VALUE, nil]
                     ];
                }
                
                // Introduction
                NSString *introduction = [thisUserInfo objectForKey:@"introduction"];
                if (introduction && [introduction length]) {
                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Introduction", nil), KEY_KEY, 
                                             [NSAttributedString stringWithString:introduction], KEY_VALUE, nil]
                     ];
                }
                
                // Verify Info
                NSString *verifyInfo = [thisUserInfo objectForKey:@"verifyinfo"];
                if (verifyInfo && [verifyInfo length]) {
                    [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             AILocalizedString(@"Verify Info", nil), KEY_KEY, 
                                             [NSAttributedString stringWithString:verifyInfo], KEY_VALUE, nil]
                    ];
                }
                
                [inContact setProfileArray:profileArray notify:NotifyNow];

            }

            // Update this user's status 
            NSString *path = @"statuses/user_timeline";
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"json",@"format",
                                    inContact.UID,@"name",
                                    @"0",@"pageflag",
                                    @"0",@"pagetime",
                                    @"10",@"reqnum",
                                    @"0",@"lastid",
                                    nil];
            [AdiumQWeiboEngine fetchDataWithAPIPath:path params:params session:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (!error) {
                    
//                    NIF_INFO(@"-- %@", responseJSON);
                    
                    NSMutableArray *profileArray = [[[inContact profileArray] mutableCopy] autorelease];
                    
                    // username - nickname pairs for replacing the username in tweets
//                    NSDictionary *nicknamePairs = [responseJSON valueForKeyPath:@"data.user"];
//                    NSArray *statuses = [responseJSON valueForKeyPath:@"data.info"];                    
                    
                    
                    NSArray *attributedTweets = [AdiumQWeiboEngine attributedTweetsFromTweetDictionary:responseJSON];

                    for (NSDictionary *attributedTweet in attributedTweets) {
                        
                        [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:attributedTweet,KEY_VALUE,nil]];                        
                    }

                    [inContact setProfileArray:profileArray notify:NotifyNow];
                }
                
            }];
            
            
        } else {
            
        }
    }];
    
//	NSString *requestID = [twitterEngine getUserInformationFor:inContact.UID];
//	
//	if(requestID) {
//		[self setRequestType:AIQWeiboProfileUserInfo
//				forRequestID:requestID
//			  withDictionary:[NSDictionary dictionaryWithObject:inContact forKey:@"ListContact"]];
//	}
}


/*!
 * @brief Should an autoreply be sent to this message?
 */
- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return NO;
}


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
//    NIF_INFO(@"icon URL : %@", url);
	// If we don't already have an icon for the user...
	if(![[listContact valueForProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON] boolValue]) {
        NSString *realURL = [url stringByAppendingFormat:@"/%d",QWEIBO_ICON_SIZE];
		
		// Grab the user icon and set it as their serverside icon.

        [self _fetchImageWithURL:realURL imageHander:^(NSImage *image) {
            
            [listContact setServersideIconData:[image TIFFRepresentation]
                                        notify:NotifyLater];
            
            [listContact setValue:nil forProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];

        }];
        
		[listContact setValue:[NSNumber numberWithBool:YES] forProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
	}
}

/*!
 * @brief Unfollow the requested contacts.
 */
- (void)removeContacts:(NSArray *)objects fromGroups:(NSArray *)groups
{	
	for (AIListContact *object in objects) {

	}
}

/*!
 * @brief Follow the requested contact, trigger an information pull for them.
 */
- (void)addContact:(AIListContact *)contact toGroup:(AIListGroup *)group
{
//    NIF_INFO(@"%@", contact);
//    NIF_INFO(@"%@", group);
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
//			[self setRequestType:AIQWeiboAddFollow
//					forRequestID:updateRequestID
//				  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:contact.UID, @"UID", nil]];
//		}
//	}
}


#pragma mark Preference updating
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{

//    NIF_INFO(@"group : %@ key : %@",group,key);

	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
//    NIF_INFO(@"");
	// We only care about our changes.
	if (object != self) {
		return;
	}
	
	if([group isEqualToString:GROUP_ACCOUNT_STATUS]) {
//        NIF_INFO(@"[group isEqualToString:GROUP_ACCOUNT_STATUS]) {");

		if([key isEqualToString:KEY_USER_ICON]) {
//            NIF_INFO(@"----------------[group isEqualToString:KEY_USER_ICON]) {");

			// Avoid pushing an icon update which we just downloaded.
			if(![self boolValueForProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON]) {
//                NIF_INFO(@"---------------self boolValueForProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON-[group isEqualToString:KEY_USER_ICON]) {");
//#warning UPLOAD MY ICON
                
//				NSString *requestID = [twitterEngine updateProfileImage:[prefDict objectForKey:KEY_USER_ICON]];
                
//				if(requestID) {
//					AILogWithSignature(@"%@ Pushing self icon update", self);
//					
//					[self setRequestType:AIQWeiboProfileSelf
//							forRequestID:requestID
//						  withDictionary:nil];
//				}
			}
			
			[self setValue:nil forProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
		}
	}
	
	if([group isEqualToString:QWEIBO_PREFERENCE_GROUP_UPDATES]) {
        if(!firstTime && [key isEqualToString:QWEIBO_PREFERENCE_UPDATE_INTERVAL]) {
        NIF_INFO(@"[group isEqualToString:GROUP_ACCOUNT_STATUS]) {");
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
//            NIF_INFO(@"fan list");
			if ([[prefDict objectForKey:QWEIBO_PREFERENCE_LOAD_CONTACTS] boolValue]) {
				// Delay updates when loading our contacts list.
				[self silenceAllContactUpdatesForInterval:18.0];
				// Grab our user list.
//				NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:1];
				
//				if (requestID) {
//					[self setRequestType:AIQWeiboInitialUserInfo
//							forRequestID:requestID
//						  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"Page"]];
//				}
//                NIF_INFO(@"fan list");
                [AdiumQWeiboEngine fetchFollowingListWithSession:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
//                    NIF_INFO(@"fan list : %@", responseJSON);
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
    NIF_INFO();
}

- (QOAuthSession *)session {
    if (_session == nil) {
        _session = [[QOAuthSession alloc] initWithIdentifier:self.internalObjectID];
    }
    return _session;
}

- (void)_updateProfileWithInfo:(NSDictionary *)json {
    
}

- (void)_fetchImageWithURL:(NSString *)url imageHander:(void(^)(NSImage *image))imageHander {
    dispatch_queue_t queue = dispatch_queue_create("com.ryan.downloadimage", NULL);
    dispatch_async(queue, ^{
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageHander(image);
        });
    });
}

- (void)dealloc {
    [_session release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
    
    [super dealloc];
}

@end
