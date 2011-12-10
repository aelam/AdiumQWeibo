//
//  AIQWeiboAccount.h
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccount.h>

#define QWEIBO_UPDATE_INTERVAL_MINUTES 20

#define QWEIBO_PREFERENCE_UPDATE_AFTER_SEND		@"QWEIBO Update After Send"
#define QWEIBO_PREFERENCE_UPDATE_GLOBAL			@"QWEIBO Update Global Status"
#define QWEIBO_PREFERENCE_UPDATE_GLOBAL_REPLIES	@"QWEIBO Update Global Status Includes Replies"
#define QWEIBO_PREFERENCE_RETWEET_SPAM			@"QWEIBO Retweet Enabled"
#define QWEIBO_PREFERENCE_LOAD_CONTACTS			@"QWEIBO Load Follows as Contacts"

#define QWEIBO_UPDATE_TIMELINE_COUNT_FIRST_RUN		50

#define QWEIBO_UPDATE_TIMELINE_COUNT		200
#define QWEIBO_UPDATE_DM_COUNT				20
#define QWEIBO_UPDATE_REPLIES_COUNT         20
#define QWEIBO_UPDATE_USER_INFO_COUNT		10


#define QWEIBO_PREFERENCE_EVER_LOADED_TIMELINE	@"QWEIBO Ever Loaded Timeline"
#define QWEIBO_PREFERENCE_UPDATE_INTERVAL		@"QWEIBO Update Interval In Minutes"
#define QWEIBO_PREFERENCE_DM_LAST_ID			@"QWEIBO Direct Messages Last ID"
#define QWEIBO_PREFERENCE_TIMELINE_LAST_ID		@"QWEIBO Followed Timeline Last ID"
#define QWEIBO_PREFERENCE_REPLIES_LAST_ID		@"QWEIBO Replies Last ID"
#define QWEIBO_PREFERENCE_GROUP_UPDATES         @"QWEIBO Preferences"



#define QWEIBO_REMOTE_GROUP_NAME			@"Tencent Weibo"
#define QWEIBO_TIMELINE_NAME				@"Timeline (%@)"

@interface AIQWeiboAccount : AIAccount {
    //    WeiboEngine *_engine;
}

@property (readonly, nonatomic) NSString *defaultServer;
@property (readonly, nonatomic) BOOL useOAuth;

@end
