//
//  AIQWeiboAccount.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccount.h>
#import "QWeibo.h"

#define QWEIBO_UPDATE_INTERVAL_MINUTES 20

#define QWEIBO_UPDATE_TIMELINE_COUNT_FIRST_RUN		50

#define QWEIBO_UPDATE_TIMELINE_COUNT		200
#define QWEIBO_UPDATE_DM_COUNT				20
#define QWEIBO_UPDATE_REPLIES_COUNT         20
#define QWEIBO_UPDATE_USER_INFO_COUNT		10

#define QWEIBO_OAUTH_NOT_AUTHORIZED		AILocalizedString(@"Adium isn't allowed access to your account.", "Error message displayed when the server reports that our access has been revoked or invalid.")
#define QWEIBO_PROPERTY_REQUESTED_USER_ICON     @"QWEIBO Requested User Icon"

#define QWEIBO_PREFERENCE_EVER_LOADED_TIMELINE	@"QWEIBO Ever Loaded Timeline"
#define QWEIBO_PREFERENCE_UPDATE_INTERVAL		@"QWEIBO Update Interval In Minutes"
#define QWEIBO_PREFERENCE_DM_LAST_ID			@"QWEIBO Direct Messages Last ID"
#define QWEIBO_PREFERENCE_TIMELINE_LAST_ID		@"QWEIBO Followed Timeline Last ID"
#define QWEIBO_PREFERENCE_REPLIES_LAST_ID		@"QWEIBO Replies Last ID"
#define QWEIBO_PREFERENCE_GROUP_UPDATES         @"QWEIBO Preferences"

#define QWEIBO_PREFERENCE_UPDATE_AFTER_SEND		@"Update After Send"
#define QWEIBO_PREFERENCE_UPDATE_GLOBAL			@"Update Global Status"
#define QWEIBO_PREFERENCE_UPDATE_GLOBAL_REPLIES	@"Update Global Status Includes Replies"
#define QWEIBO_PREFERENCE_RETWEET_SPAM				@"Retweet Enabled"
#define QWEIBO_PREFERENCE_LOAD_CONTACTS			@"Load Follows as Contacts"

#define QWEIBO_REMOTE_GROUP_NAME			@"Tencent Weibo"
#define QWEIBO_TIMELINE_NAME				@"Timeline (%@)"

#define QWEIBO_WEBPAGE                      @"http://t.qq.com"

@interface AIQWeiboAccount : AIAccount {
    QOAuthSession       *_session;
    
    NSTimer				*updateTimer;

}

@property (readonly, nonatomic) NSString *defaultServer;
@property (readonly, nonatomic) BOOL useOAuth;
@property (readonly, nonatomic) QOAuthSession *session;

@property (readonly, nonatomic) NSString *timelineChatName;

- (void)periodicUpdate;


@end
