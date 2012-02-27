//
//  AIQWeiboAccount.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccount.h>
#import "QWeibo.h"

typedef enum {
	AIQWeiboUnknownType = 0,
	
	AIQWeiboValidateCredentials,
	AIQWeiboDisconnect,
	
	AIQWeiboRateLimitStatus,
	
	AIQWeiboInitialUserInfo,
	AIQWeiboAddFollow,
	AIQWeiboRemoveFollow,
	
	AIQWeiboProfileSelf,
	AIQWeiboSelfUserIconPull,
	
	AIQWeiboProfileUserInfo,
	AIQWeiboProfileStatusUpdates,
	AIQWeiboUserIconPull,
	
	AIQWeiboDirectMessageSend,  // 发送私信
	AIQWeiboSendUpdate,
	
	AIQWeiboUpdateDirectMessage,
	AIQWeiboUpdateFollowedTimeline,
	AIQWeiboUpdateReplies,
	
	AIQWeiboFavoriteYes,
	AIQWeiboFavoriteNo,
	
	AIQWeiboNotificationEnable,
	AIQWeiboNotificationDisable,
	
	AIQWeiboDestroyStatus,
	AIQWeiboDestroyDM
} AIQWeiboRequestType;


typedef enum {
    PrivateMessageFinishedFlagInitial   = 0,
    PrivateMessageFinishedFlagInbox     = 1,
    PrivateMessageFinishedFlagOutbox    = 1<<1,
    PrivateMessageFinishedFlagDone      = 3

}PrivateMessageFinishedFlag;

#define QWEIBO_UPDATE_INTERVAL_MINUTES              20

#define QWEIBO_UPDATE_TIMELINE_COUNT_FIRST_RUN		50

#define QWEIBO_UPDATE_TIMELINE_COUNT		1000
#define QWEIBO_UPDATE_DM_COUNT				20
#define QWEIBO_UPDATE_REPLIES_COUNT         20
#define QWEIBO_UPDATE_USER_INFO_COUNT		10


#define QWEIBO_INCORRECT_PASSWORD_MESSAGE	AILocalizedString(@"Incorrect username or password","Error message displayed when the server reports username or password as being incorrect.")

#define QWEIBO_OAUTH_NOT_AUTHORIZED		AILocalizedString(@"Adium isn't allowed access to your account.", "Error message displayed when the server reports that our access has been revoked or invalid.")

#define QWEIBO_PROPERTY_REQUESTED_USER_ICON     @"QWeibo Requested User Icon"

#define QWEIBO_PREFERENCE_EVER_LOADED_TIMELINE	@"QWeibo Ever Loaded Timeline"
#define QWEIBO_PREFERENCE_UPDATE_INTERVAL		@"QWeibo Update Interval In Minutes"
#define QWEIBO_PREFERENCE_DM_LAST_ID			@"QWeibo Direct Messages Last ID"
#define QWEIBO_PREFERENCE_REPLIES_LAST_ID		@"QWeibo Replies Last ID"
#define QWEIBO_PREFERENCE_GROUP_UPDATES         @"QWeibo Preferences"

#define QWEIBO_PREFRENCE_INBOX_LAST_ID          @"QWeibo Inbox LastID"
#define QWEIBO_PREFRENCE_OUTBOX_LAST_ID         @"QWeibo Outbox LastID"



#define QWEIBO_PREFERENCE_TIMELINE_LAST_TIME	@"QWeibo Followed Timeline Last Time"


#define QWEIBO_PREFERENCE_UPDATE_AFTER_SEND		@"Update After Send"
#define QWEIBO_PREFERENCE_UPDATE_GLOBAL			@"Update Global Status"
#define QWEIBO_PREFERENCE_UPDATE_GLOBAL_REPLIES	@"Update Global Status Includes Replies"
#define QWEIBO_PREFERENCE_RETWEET_SPAM			@"Retweet Enabled"
#define QWEIBO_PREFERENCE_LOAD_CONTACTS			@"Load Follows as Contacts"
#define QWEIBO_PREFERENCE_SYNC_ITUNES           @"Sync iTunes info While listening to music"

#define QWEIBO_REMOTE_GROUP_NAME			@"Tencent Weibo"
#define QWEIBO_TIMELINE_NAME				@"Timeline (%@)"

#define QWEIBO_WEBPAGE                      @"http://t.qq.com"


// last tweet it's an array
#define QWEIBO_INFO_STATUS                  @"tweet"  
#define QWEIBO_INFO_STATUS_TEXT             @"text"

#define QWEIBO_ICON_SIZE                    120

//
// TWEET DICTIONARY KEY 
// 
#define TWEET_CREATE_AT                     @"timestamp"
#define QWEIBO_INFO_ICON_URL                @"head"
#define QWEIBO_INFO_UID                     @"name"
#define QWEIBO_INFO_SCREEN_NAME             @"nick"

#define COUNT_UPDATE_TWEET                  70

@interface AIQWeiboAccount : AIAccount {
    QOAuthSession       *_session;
    
    NSTimer				*updateTimer;
    
    __block BOOL        isLoadingHomeTimeline;
    BOOL                isLoadingInbox;
    BOOL                isLoadingOutbox;
    
    BOOL                contactListDidLoad;
    
    NSMutableArray      *privateMessages;
    
    NSMutableDictionary *_maybeDuplicateTweets;
    
    BOOL                _isESiTunesPluginLoaded;
    
    NSDictionary        *iTunesInfo;
    
    BOOL				updateAfterSend;

}

@property (readonly, nonatomic) NSString *defaultServer;
@property (readonly, nonatomic) BOOL useOAuth;
@property (readonly, nonatomic) QOAuthSession *session;

@property (readonly, nonatomic) NSString *timelineChatName;

- (AIChat *)timelineChat;
- (void)periodicUpdate;

- (void)uploadNick:(NSString *)newNick website:(NSString *)website location:(NSString *)location description:(NSString *)desc;

@end
