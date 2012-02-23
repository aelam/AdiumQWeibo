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
#import "ESiTunesPlugin.h"

#import "NSDictionary+Response.h"
#import <Adium/AIControllerProtocol.h>
#import "AdiumQWeiboEngine.h"
#import "AdiumQWeiboEngine+Helper.h"
#import "Tweet.h"
#import "NSString+Readable.h"


NSInteger TweetSorter(id tweet1, id tweet2, void *context) {
    return [[tweet1 objectForKey:TWEET_CREATE_AT] compare:[tweet2 objectForKey:TWEET_CREATE_AT]];
}

@interface AIQWeiboAccount (Private)

- (void)_fetchImageWithURL:(NSString *)url imageHander:(void(^)(NSImage *image))imageHander;
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;
- (NSString *)addressForLinkType:(AIQWeiboLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context;

- (void)_loadHomeTimelineStartPageTime:(double)date count:(NSInteger)count max:(NSInteger)max;
- (void)_resetHomeTimelineRequest;

- (void)_loadHomeTimeline;
- (void)_loadPrivateMessages;

@end

@implementation AIQWeiboAccount

- (void)initAccount {
    [super initAccount];

    _maybeDuplicateTweets = [[NSMutableDictionary alloc] init];
    privateMessages = [[NSMutableArray alloc] init];
    
    _isESiTunesPluginLoaded = NSClassFromString(@"ESiTunesPlugin")!=nil;
    NIF_INFO(@"_isESiTunesPluginLoaded : %d", _isESiTunesPluginLoaded);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatDidOpen:) 
                                                 name:Chat_DidOpen
                                               object:nil];
	
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:YES], QWEIBO_PREFERENCE_UPDATE_AFTER_SEND,
												  [NSNumber numberWithInt:QWEIBO_UPDATE_INTERVAL_MINUTES],QWEIBO_PREFERENCE_UPDATE_INTERVAL,
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
            
            NSString *imageURL = [head stringByAppendingFormat:@"/%d",QWEIBO_ICON_SIZE];
            [self _fetchImageWithURL:imageURL imageHander:^(NSImage *image) {

//                NIF_TRACE(@"My head : %@", imageURL);

                [self setValue:[NSNumber numberWithBool:YES] forProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];                    
                
                if (image) {
                    [self setPreference:[NSNumber numberWithBool:YES]
                                 forKey:KEY_USE_USER_ICON
                                  group:GROUP_ACCOUNT_STATUS];
                    
                    
                    [self setPreference:[image TIFFRepresentation]
                                 forKey:KEY_USER_ICON
                                  group:GROUP_ACCOUNT_STATUS];                    
                }
            }];
                        
			// Our UID is definitely set; grab our friends.
			if ([[self preferenceForKey:QWEIBO_PREFERENCE_LOAD_CONTACTS group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue]) {
				// If we load our follows as contacts, do so now.
				// Delay updates on initial login.
				[self silenceAllContactUpdatesForInterval:18.0];
				// Grab our user list.
                
                [AdiumQWeiboEngine fetchFollowingListFromPage:0 session:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                    
                    if(!self.online || error) {
                        NIF_ERROR(@"%@", error);
                        contactListDidLoad = YES;
                        [self _loadPrivateMessages];
                        return ;
                    }
                    
                    NSInteger hasNext = -1;
                    id data = [responseJSON objectForKey:@"data"];
                    if (data && [data respondsToSelector:@selector(objectForKey:)]) {
                        id hasnext_ = [data objectForKey:@"hasnext"];
                        if (hasnext_) {
                            hasNext = [hasnext_ intValue];
                        }
                    }
                    
                    if (!error && hasNext == 0) {
                        contactListDidLoad = NO;
                    } else {
                        contactListDidLoad = YES;
                        [self _loadPrivateMessages];
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
	
    // track iTunes status
    BOOL synciTunes = [[self preferenceForKey:QWEIBO_PREFERENCE_SYNC_ITUNES group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];
    NIF_INFO(@"synciTunes ? %d", synciTunes);
    if (_isESiTunesPluginLoaded && synciTunes) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iTunesDidUpdate:) name:Adium_iTunesTrackChangedNotification object:nil];
    }
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
            //QWEIBO_REMOTE_GROUP_NAME
        }       
    }
    
    NSTimeInterval updateInterval = [[self preferenceForKey:QWEIBO_PREFERENCE_UPDATE_INTERVAL group:QWEIBO_PREFERENCE_GROUP_UPDATES] integerValue] * 60;
    NIF_INFO(@"updateInterval = %lf", updateInterval);
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Adium_iTunesTrackChangedNotification object:nil];
    [iTunesInfo release]; iTunesInfo = nil;
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
	
    NIF_INFO(@"%@", chat);
    
	if(chat.isGroupChat && chat.account == self) {
        [self updateTimelineChat:chat];
//        NIF_INFO();
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

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage {
    
    NIF_INFO(@"sending message out.... %@",inContentMessage.chat);
//    NIF_INFO(@"%@",inContentMessage);
    
    AIChat *timelineChat = self.timelineChat;
    inContentMessage.displayContent = NO;

    NSString *encodedMessage = inContentMessage.encodedMessage;

    if(inContentMessage.chat == timelineChat) {
        NIF_INFO(@"do you mean send a tweet ?");
        [AdiumQWeiboEngine sendTweetWithSession:self.session content:encodedMessage resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
            NIF_INFO(@"YES, send it out for me ");
            if (error) {
                NIF_ERROR(@"%@", error);
            } else {
                NIF_TRACE(@"%@", responseJSON);
                NSInteger errorCode = [[responseJSON objectForKey:@"errcode"] intValue];
                NSInteger ret = [[responseJSON objectForKey:@"ret"] intValue];
                if (ret == 0 && errorCode == 0) {
                    id data = [responseJSON objectForKey:@"data"];
                    if (data) {
                        /*
                        NSTimeInterval time = [[data objectForKey:@"time"] doubleValue];
                        [adium.contentController displayEvent:AILocalizedString(@"Tweet successfully sent.", nil)
                                                       ofType:@"tweet"
                                                       inChat:self.timelineChat];

                        
                        NSDate *receivedDate = [NSDate dateWithTimeIntervalSince1970:time]; 
                                                
                        AIContentMessage *contentMessage = [AIContentMessage messageInChat:self.timelineChat withSource:self destination:self date:receivedDate message:inContentMessage.message autoreply:NO];
                        [adium.contentController receiveContentObject:contentMessage];
                    */

                        [adium.contentController displayEvent:AILocalizedString(@"Tweet successfully sent.", nil)
                                                       ofType:@"tweet"
                                                       inChat:self.timelineChat];

                        updateAfterSend = [[self preferenceForKey:QWEIBO_PREFERENCE_UPDATE_AFTER_SEND group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];
                        NIF_INFO(@"updateAfterSend ?: %d", updateAfterSend);
                        [self periodicUpdate];
                    } else {
                        [adium.contentController displayEvent:AILocalizedString(@"Tweet sent fail", nil)
                                                       ofType:@"tweet"
                                                       inChat:self.timelineChat];                        
                    }
                } else {
                    [adium.contentController displayEvent:AILocalizedString(@"Tweet sent fail", nil)
                                                   ofType:@"tweet"
                                                   inChat:self.timelineChat];
                }
            }
        }];
    } else {
        NSString *destinationID = inContentMessage.destination.UID;
        if (destinationID && destinationID.length && encodedMessage && [encodedMessage length]) {
            [AdiumQWeiboEngine sendPrivateMessageWithSession:self.session message:encodedMessage toUser:destinationID resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
               /*
                id data = [responseJSON objectForKey:@"data"];
                if ([data respondsToSelector:@selector(objectForKey:)]) {
                    NSNumber *messageID = [data objectForKey:@"id"];
                    NSNumber *messageTime = [data objectForKey:@"time"];
                    if (messageID && messageTime) {
                        NSDate *receivedDate = [NSDate dateWithTimeIntervalSince1970:[messageTime doubleValue]];

                        AIContentMessage *contentMessage = [AIContentMessage messageInChat:inContentMessage.chat withSource:self destination:destinationID date:receivedDate message:inContentMessage.message autoreply:NO];
                        [adium.contentController receiveContentObject:contentMessage];
                    }
                }*/
                NIF_INFO(@"sending private message");
                NIF_INFO(@"%@", responseJSON);
                NSInteger errorCode = [[responseJSON objectForKey:@"errcode"] intValue];
                NSInteger ret = [[responseJSON objectForKey:@"ret"] intValue];
                if (ret == 0 && errorCode == 0) {
                    id data = [responseJSON objectForKey:@"data"];
                    if (data) {
                        [adium.contentController displayEvent:AILocalizedString(@"Private message successfully sent.", nil)
                                                       ofType:@"tweet"
                                                       inChat:inContentMessage.chat];
                        
                        updateAfterSend = [[self preferenceForKey:QWEIBO_PREFERENCE_UPDATE_AFTER_SEND group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];
                        NIF_INFO(@"updateAfterSend ?: %d", updateAfterSend);
                        [self periodicUpdate];
                    } else {
                        [adium.contentController displayEvent:AILocalizedString(@"Private message sent fail", nil)
                                                       ofType:@"tweet"
                                                       inChat:inContentMessage.chat];                        
                    }
                } else {
                    [adium.contentController displayEvent:AILocalizedString(@"Private message sent fail", nil)
                                                   ofType:@"tweet"
                                                   inChat:inContentMessage.chat];
                }

                
            }];
        }
        
    }
    
    return YES;
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
        if (error) {
            NIF_ERROR(@"%@" ,error);
        } else {
            NSDictionary *thisUserInfo = [responseJSON objectForKey:@"data"];

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
            
            [AdiumQWeiboEngine fetchUserTimelineWithSession:self.session forUser:inContact.UID since:nil lastID:0 pageFlag:0 count:10 resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (error) {
                    NIF_ERROR(@"%@" ,error);
                } else {
                    NSMutableArray *profileArray = [[[inContact profileArray] mutableCopy] autorelease];
                    NSArray *attributedTweets = [AdiumQWeiboEngine attributedTweetsFromTweetDictionary:responseJSON];

                    for (NSDictionary *attributedTweet in attributedTweets) {
                        
                        [profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:attributedTweet,KEY_VALUE,nil]];                        
                    }
                    [inContact setProfileArray:profileArray notify:NotifyNow];
                }
            }];
        }
    }];

}


/*!
 * @brief Should an autoreply be sent to this message?
 */
- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return NO;
}


#pragma PLUS Function : iTunes
- (void)iTunesDidUpdate:(NSNotification *)notification {
//    NIF_INFO(@"%@", notification);
    [iTunesInfo release];
    iTunesInfo = [[notification object] retain];
    
    BOOL synciTunes = [[self preferenceForKey:QWEIBO_PREFERENCE_SYNC_ITUNES group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];
    if (!synciTunes) {
        return;
    }
    
    NSString *name = [iTunesInfo objectForKey:ITUNES_NAME];
    NSString *artist = [iTunesInfo objectForKey:ITUNES_ARTIST];
    NSString *storeURL = [iTunesInfo objectForKey:ITUNES_STORE_URL];

    if (!name || !artist || !storeURL) {
        return;
    }
    NSString *content = [NSString stringWithFormat:@"%@ %@ - %@ , %@ #iTunes#",AILocalizedString(@"正在听",@"Listening to"),EmptyString(name),EmptyString(artist),EmptyString(storeURL)];
    
    NIF_INFO(@"do you mean send a tweet ?,%@",content);
    [AdiumQWeiboEngine sendTweetWithSession:self.session content:content resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        NIF_INFO(@"YES, send it out for me ");
        if (error) {
            NIF_ERROR(@"%@", error);
        } else {
            NIF_TRACE(@"%@", responseJSON);
            NSInteger errorCode = [[responseJSON objectForKey:@"errcode"] intValue];
            NSInteger ret = [[responseJSON objectForKey:@"ret"] intValue];
            if (ret == 0 && errorCode == 0) {
                id data = [responseJSON objectForKey:@"data"];
                if (data) {
                    /*
                     NSTimeInterval time = [[data objectForKey:@"time"] doubleValue];
                     [adium.contentController displayEvent:AILocalizedString(@"Tweet successfully sent.", nil)
                     ofType:@"tweet"
                     inChat:self.timelineChat];
                     
                     
                     NSDate *receivedDate = [NSDate dateWithTimeIntervalSince1970:time]; 
                     
                     AIContentMessage *contentMessage = [AIContentMessage messageInChat:self.timelineChat withSource:self destination:self date:receivedDate message:inContentMessage.message autoreply:NO];
                     [adium.contentController receiveContentObject:contentMessage];
                     */
                    
                    [adium.contentController displayEvent:AILocalizedString(@"Tweet successfully sent.", nil)
                                                   ofType:@"tweet"
                                                   inChat:self.timelineChat];
                    
                    updateAfterSend = [[self preferenceForKey:QWEIBO_PREFERENCE_UPDATE_AFTER_SEND group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];
                    NIF_INFO(@"updateAfterSend ?: %d", updateAfterSend);
                    [self periodicUpdate];
                } else {
                    [adium.contentController displayEvent:AILocalizedString(@"Tweet sent fail", nil)
                                                   ofType:@"tweet"
                                                   inChat:self.timelineChat];                        
                }
            } else {
                [adium.contentController displayEvent:AILocalizedString(@"Tweet sent fail", nil)
                                               ofType:@"tweet"
                                               inChat:self.timelineChat];
            }
        }
    }];
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


- (void)uploadNick:(NSString *)newNick website:(NSString *)website location:(NSString *)location description:(NSString *)desc {
    
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
        [AdiumQWeiboEngine unfollowUserWithSession:self.session user:object.UID resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (error) {
                NIF_ERROR(@"%@", error);
                [adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Remove Contact", nil)
                                              withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to remove %@ on account %@. %@", nil),
                                                               object.UID,
                                                               self.explicitFormattedUID,
                                                               @"What's up?"]];

            } else {
//                NIF_INFO(@"%@", responseJSON);
                NSInteger errorCode = [[responseJSON objectForKey:@"errcode"] intValue];
                NSInteger ret = [[responseJSON objectForKey:@"ret"] intValue];
                if (ret == 0 && errorCode == 0) {
                    NIF_TRACE(@"delete %@ success !!",object.UID);
                    for (NSString *groupName in object.remoteGroupNames) {
                        [object removeRemoteGroupName:groupName];
                    }                    
                }
            }
        }];
	}
}

/*!
 * @brief Follow the requested contact, trigger an information pull for them.
 */
- (void)addContact:(AIListContact *)contact toGroup:(AIListGroup *)group
{
	if ([contact.UID isCaseInsensitivelyEqualToString:self.UID]) {
		NIF_ERROR(@"Not adding contact %@ to group %@, it's me!", contact.UID, group.UID);
		return;
	}
    
    [AdiumQWeiboEngine followUserWithSession:self.session user:contact.UID resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error) {
            NIF_ERROR(@"%@", error);
        } else {
            if(error.code == 404) {
				[adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Add Contact", nil)
											  withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to add %@ to account %@, the user does not exist.", nil),
															   contact.UID,
															   self.explicitFormattedUID]];
			} else {
				[adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Add Contact", nil)
											  withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to add %@ to account %@. %@",nil),
															  contact.UID,
															   self.explicitFormattedUID,
															   @"can't add...... "]];
			}

        }
    }];
    
}


#pragma mark Preference updating
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
	// We only care about our changes.
	if (object != self) {
		return;
	}
	
	if([group isEqualToString:GROUP_ACCOUNT_STATUS]) {

		if([key isEqualToString:KEY_USER_ICON]) {

			// Avoid pushing an icon update which we just downloaded.
			if(![self boolValueForProperty:QWEIBO_PROPERTY_REQUESTED_USER_ICON]) {
                //NIF_TRACE(@"KEY_USER_ICON : %@", [prefDict objectForKey:KEY_USER_ICON]);
                // TODO
                // 修改图片
                NIF_TRACE(@"modify my icon...");
                NSData *imageData = [prefDict objectForKey:KEY_USER_ICON];
//                [imageData writeToFile:@"/Users/ryan/Desktop/test.jpg" atomically:YES];
                if (imageData) {
                    [AdiumQWeiboEngine updateHeadIcon:imageData session:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if(error) {
                            NIF_ERROR(@"%@", error);
                        } else {
                            NIF_TRACE(@"%@", responseJSON);
                        }
                    }];                    
                }
                
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

			if ([[prefDict objectForKey:QWEIBO_PREFERENCE_LOAD_CONTACTS] boolValue]) {
				// Delay updates when loading our contacts list.
				[self silenceAllContactUpdatesForInterval:18.0];
                [AdiumQWeiboEngine fetchFollowingListWithSession:self.session resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if (error) {
                        NIF_ERROR(@"%@" ,error);
                    } else {
                    }
                }];
                
                
			} else {
				[self removeAllContacts];
			}
		}
        if ([key isEqualToString:QWEIBO_PREFERENCE_SYNC_ITUNES] && self.online) {
            BOOL synciTunes = [[prefDict objectForKey:QWEIBO_PREFERENCE_SYNC_ITUNES] boolValue];//[[self preferenceForKey:QWEIBO_PREFERENCE_SYNC_ITUNES group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];
            
            if (_isESiTunesPluginLoaded && synciTunes) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iTunesDidUpdate:) name:Adium_iTunesTrackChangedNotification object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:Adium_iTunesTrackChangedNotification object:nil];
            }
            NIF_INFO(@"sync iTunes opened ? %d  ll 2 : %d", synciTunes,[[self preferenceForKey:QWEIBO_PREFERENCE_SYNC_ITUNES group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue]);
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
    
    if(contactListDidLoad) {
        NIF_INFO(@"update private messages");
        [self _loadPrivateMessages];        
    }
    
    if (!isLoadingHomeTimeline) {
        [self _loadHomeTimeline];
    }
}

- (void)_loadHomeTimeline {
    NSString *lastUpdateTime = [self preferenceForKey:QWEIBO_PREFERENCE_TIMELINE_LAST_TIME group:QWEIBO_PREFERENCE_GROUP_UPDATES];
    double lastUpdateTime_ = [lastUpdateTime doubleValue];
    double currentTimestamp = [[NSDate date]timeIntervalSince1970];
    
    // 
    // if we have not loaded timeline for a long time, there will be too many tweets,
    // so we'd better change the timestamp that we need load begin
    //
    if (currentTimestamp - lastUpdateTime_ > 7200 || lastUpdateTime_ == 0) {
        lastUpdateTime_ = currentTimestamp - 2000;
    }
    
    [self _loadHomeTimelineStartPageTime:lastUpdateTime_ count:COUNT_UPDATE_TWEET max:200];
    
}


- (void)_loadHomeTimelineStartPageTime:(double)date count:(NSInteger)count max:(NSInteger)max {
    NIF_INFO(@"loading from  : %@",    [[NSDate dateWithTimeIntervalSince1970:date] descriptionWithLocale:[NSLocale currentLocale]]);

    [AdiumQWeiboEngine fetchHomeTimelineWithSession:self.session pageTime:date pageFlag:PageFlagPageUp count:count resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error) {
            NIF_ERROR(@"%@" ,error);
            [self _resetHomeTimelineRequest];
        } else {
            
            NSDictionary *data = [responseJSON objectForKey:@"data"];

            if (data == nil || [data isKindOfClass:[NSString class]]) {
                NIF_INFO(@"data is nil");
                [self _resetHomeTimelineRequest];
            } else {
                AIChat *timelineChat = self.timelineChat;
                
                NSDictionary *nicknamePairs = [data objectForKey:@"user"];
                NSArray *statuses = [data objectForKey:@"info"];                    
                
                BOOL trackContent = [[self preferenceForKey:QWEIBO_PREFERENCE_EVER_LOADED_TIMELINE group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];
                
                [[AIContactObserverManager sharedManager] delayListObjectNotifications];
                
                for (NSDictionary *status in [statuses reverseObjectEnumerator]) {
                    NSString *plainTweet = [status objectForKey:@"origtext"];
                    
                    NSMutableAttributedString *finallyAttributedTweet = [[[NSMutableAttributedString alloc] init] autorelease];
                    
                    NSAttributedString *attributedTweet = [AdiumQWeiboEngine attributedTweetForPlainText:plainTweet replacingNicknames:nicknamePairs processEmotion:NO];
                    
                    // 
                    // If this tweet is retweet by you, I will mark it before this tweet AS RT(转播) 
                    //
                    ResponseTweetType type = [[status objectForKey:@"type"] intValue];
                    if(type == ResponseTweetTypeRetweet) {
                        NSDictionary *source = [status objectForKey:@"source"];
                        [finallyAttributedTweet appendString:@"转播: " withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor lightGrayColor],NSForegroundColorAttributeName,[NSColor yellowColor],NSBackgroundColorAttributeName,nil]];
                        if(attributedTweet) {
                            [finallyAttributedTweet appendAttributedString:attributedTweet];
                        }
                        if (source) {
                            [finallyAttributedTweet appendString:@"\n" withAttributes:nil];
                            NSString *origName = [source objectForKey:@"name"];
                            NSString *origNick = [source objectForKey:@"nick"];
                            NSAttributedString *attributedUser = [AdiumQWeiboEngine attributedUserWithName:origName nick:origNick];
                            
                            NSString *plainTweet2 = [source objectForKey:@"origtext"];
                            NSAttributedString *attributedTweet2 = [AdiumQWeiboEngine attributedTweetForPlainText:plainTweet2 replacingNicknames:nicknamePairs processEmotion:NO];
                            
                            if (attributedUser) {
                                [finallyAttributedTweet appendAttributedString:attributedUser];
                                [finallyAttributedTweet appendString:@":" withAttributes:nil];                                
                            }
                            if (attributedTweet2) {
                                [finallyAttributedTweet appendAttributedString:attributedTweet2];
                            }
                        } else {
                            
                        }
                    } else if(type == ResponseTweetTypeOriginal){
                        if(attributedTweet) {
                            [finallyAttributedTweet appendAttributedString:attributedTweet];                            
                        }
                    }
                    
                    
                    
                    NSString *contactUID = [status objectForKey:QWEIBO_INFO_UID];
                    double timestamp = [[status objectForKey:TWEET_CREATE_AT] doubleValue];
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
                    
                    
                    id fromObject = nil;
                    
                    if(![self.UID isCaseInsensitivelyEqualToString:contactUID]) {
                        AIListContact *listContact = [self contactWithUID:contactUID];
                        [listContact setStatusMessage:[NSAttributedString stringWithString:[plainTweet stringByUnescapingFromXMLWithEntities:nil]] notify:NotifyNow];
                        [self updateUserIcon:[status objectForKey:QWEIBO_INFO_ICON_URL] forContact:listContact];
                        
                        [timelineChat addParticipatingListObject:listContact notify:NotifyNow];
                        
                        fromObject = (id)listContact;
                        
                    } else {
                        fromObject = (id)self;
                    }
                    
                    AIContentMessage *contentMessage = [AIContentMessage messageInChat:timelineChat
                                                                            withSource:fromObject
                                                                           destination:self
                                                                                  date:date
                                                                               message:finallyAttributedTweet
                                                                             autoreply:NO];
                    
                    contentMessage.trackContent = trackContent;
                    [adium.contentController receiveContentObject:contentMessage];
                }
                
                [[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
                
                [self _resetHomeTimelineRequest];
                
                // new lastID should be marked here 
                id firstStatus = [statuses objectAtIndex:0];
                double futureTimelineLastTime = [[firstStatus objectForKey:@"timestamp"] doubleValue];
                NSString *futureTimelineLastTime_ = [NSString stringWithFormat:@"%0.0f",futureTimelineLastTime];
                
                [self setPreference:futureTimelineLastTime_
                             forKey:QWEIBO_PREFERENCE_TIMELINE_LAST_TIME
                              group:QWEIBO_PREFERENCE_GROUP_UPDATES];
                // let's load more 
                
                if(data && [data respondsToSelector:@selector(objectForKey:)] && [statuses count] > 0) {
                    // hasnext == 0 ==> hasNextPage == YES
                    BOOL hasNextPage = [data objectForKey:@"hasnext"] &&([[data objectForKey:@"hasnext"] intValue]==0);
                    NIF_TRACE(@"do we have next page ? %d",hasNextPage);
                    
                    NSInteger leftTweetsCount = max - [statuses count];
                    if (hasNextPage && leftTweetsCount > 0 ) {
                        NIF_TRACE(@"IM LOADING MORE HOMTIMELINE....");
                        [self _loadHomeTimelineStartPageTime:futureTimelineLastTime count:count max:leftTweetsCount];
                    } else {
                        [self _resetHomeTimelineRequest];
                    }
                } else {
                    [self _resetHomeTimelineRequest];
                }                
            }
        }
    }];

}

- (void)_resetHomeTimelineRequest {
    isLoadingHomeTimeline = NO;
}

- (void)_loadPrivateMessages {    
    if(isLoadingInbox || isLoadingOutbox) {
        return;
    }
    
    dispatch_block_t finishedBlock = ^{
        
        if (isLoadingInbox == NO && isLoadingOutbox == NO) {
            NIF_INFO(@"need sort");
            NSArray *sortedMessages = [privateMessages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                double time1 = [[obj1 objectForKey:@"timestamp"] doubleValue];
                double time2 = [[obj1 objectForKey:@"timestamp"] doubleValue];
                if (time1 < time2) {
                    return NSOrderedAscending;
                } else if (time1 == time2) {
                    return NSOrderedSame;
                } else {
                    return NSOrderedDescending;
                }
            }];
            
            NIF_INFO(@"sortedMessages count = %d", [sortedMessages count]);
            
            for (NSDictionary *status in sortedMessages) {
                
                NSString *plainTweet = [status objectForKey:@"origtext"];
                NSString *contactUID = [status objectForKey:QWEIBO_INFO_UID];
                double timestamp = [[status objectForKey:TWEET_CREATE_AT] doubleValue];
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
                BOOL isSentByMe = [[status objectForKey:@"self"] boolValue];
                // 1 发件箱 0 收件箱
                
                NSAttributedString *attributedTweet = [AdiumQWeiboEngine attributedTweetForPlainText:plainTweet replacingNicknames:nil processEmotion:NO];
                                
                id fromObject = nil;                
                id destination = nil;
                AIListContact *listContact = [self contactWithUID:contactUID];

                if (isSentByMe) {
                    NSString *toUser = [status objectForKey:@"toname"];
                    contactUID = toUser;
                    listContact = [self contactWithUID:toUser];
                    NIF_INFO(@"to User : %@, listContact : %@", toUser,listContact);
                    fromObject = self;//[self contactWithUID:contactUID];;
                    destination = listContact;
                } else {
                    listContact = [self contactWithUID:contactUID];
                    fromObject = listContact;
                    destination = self;
                }
                
                AIChat *chat = [adium.chatController existingChatWithIdentifier:contactUID
                                                                onAccount:self];
                
                if (!chat) {
                    chat = [adium.chatController chatWithContact:listContact];
                }
                
                BOOL trackContent = [[self preferenceForKey:QWEIBO_PREFERENCE_EVER_LOADED_TIMELINE group:QWEIBO_PREFERENCE_GROUP_UPDATES] boolValue];

                AIContentMessage *contentMessage = [AIContentMessage messageInChat:chat
                                                      withSource:fromObject
                                                     destination:destination
                                                            date:date
                                                         message:attributedTweet
                                                       autoreply:NO];                    
                
                            
                contentMessage.trackContent = trackContent;
                [adium.contentController receiveContentObject:contentMessage];
            }
            
            // reset
            [privateMessages removeAllObjects];
            isLoadingOutbox = NO;
            isLoadingInbox = NO;
        } 
    };
    
        
    NSString *lastInboxID = [self preferenceForKey:QWEIBO_PREFRENCE_INBOX_LAST_ID group:QWEIBO_PREFERENCE_GROUP_UPDATES];
    NSString *lastOutboxID = [self preferenceForKey:QWEIBO_PREFRENCE_OUTBOX_LAST_ID group:QWEIBO_PREFERENCE_GROUP_UPDATES];
    
    [AdiumQWeiboEngine getInboxMessagesWithSession:self.session sinceID:lastInboxID resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSInteger hasNext = -1;
        id data = [responseJSON objectForKey:@"data"];
        if (data && [data respondsToSelector:@selector(objectForKey:)] && !error) {
            id info = [data objectForKey:@"info"];
            if (!info || [info count] == 0) {
                isLoadingInbox = NO;
                finishedBlock();
            } else {
                id lastest = [info objectAtIndex:0];
                NSString *newlastID = [[lastest objectForKey:@"timestamp"] description];
                [self setPreference:newlastID
                             forKey:QWEIBO_PREFRENCE_INBOX_LAST_ID
                              group:QWEIBO_PREFERENCE_GROUP_UPDATES];
                
                id messages = [data objectForKey:@"info"];
                NIF_INFO(@"inbox count : %d", [messages count]);
                NIF_INFO(@"newlastID : %@", newlastID);
                if (messages && [messages count]) {
                    [privateMessages addObjectsFromArray:messages];                    
                }
                
                id hasnext_ = [data objectForKey:@"hasnext"];
                if (hasnext_) {
                    hasNext = [hasnext_ intValue];
                }
                
                NIF_INFO(@"hasnext_，%@ hasNext : %d",hasnext_,hasNext);

                if(hasNext != 0){    // 没有下页
                    NIF_INFO(@"Inbox hasNext != 0");
                    isLoadingInbox = NO;
                    finishedBlock();
                } else {
                    isLoadingInbox = YES;
                }
            }
        } else {
            isLoadingInbox = NO;
            finishedBlock();
        }
    }];
    
    [AdiumQWeiboEngine getOutboxMessagesWithSession:self.session sinceID:lastOutboxID resultHandler:^(NSDictionary *responseJSON, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSInteger hasNext = -1;
        id data = [responseJSON objectForKey:@"data"];
        if (data && [data respondsToSelector:@selector(objectForKey:)]) {
            id info = [data objectForKey:@"info"];
            if (!info || [info count] == 0) {
                isLoadingOutbox = NO;
                finishedBlock();
            } else {

                id messages = [data objectForKey:@"info"];
                if (messages && [messages count]) {
                    [privateMessages addObjectsFromArray:messages];                    
                }

                id lastest = [info objectAtIndex:0];
                NSString *newlastID = [[lastest objectForKey:@"timestamp"] description];
                NIF_INFO(@"outbox count : %d", [[data objectForKey:@"info"] count]);
                NIF_INFO(@"newlastID : %@", newlastID);

                [self setPreference:newlastID
                             forKey:QWEIBO_PREFRENCE_OUTBOX_LAST_ID
                              group:QWEIBO_PREFERENCE_GROUP_UPDATES];
                
                id hasnext_ = [data objectForKey:@"hasnext"];
                if (hasnext_) {
                    hasNext = [hasnext_ intValue];
                }
                
                NIF_INFO(@"hasNext : %d", hasNext);
                if(hasNext != 0){
                    NIF_INFO(@"Outbox hasNext != 0");
                    isLoadingInbox = NO;
                    finishedBlock();
                } else {
                    isLoadingInbox = YES;
                }
            }
        } else {
            isLoadingInbox = NO;
            finishedBlock();
        }
    }];

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
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        NSImage *image = [[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:url]] autorelease];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageHander(image);
        });
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];

    [_session release];
    [_maybeDuplicateTweets release];
    [privateMessages release];
    
    [super dealloc];
}

@end
