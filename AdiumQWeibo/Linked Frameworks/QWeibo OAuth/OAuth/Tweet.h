//
//  Tweet.h
//  AdiumQWeibo
//
//  Created by Ryan Wang Wang on 12-2-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AdiumQWeiboEngine.h"

@interface Tweet : NSObject {
    NSString            *_tweetID;
    NSString            *_nick;
    NSString            *_name;
    double              _timestamp;
    ResponseTweetType   _tweetType;
    Tweet               *_souceTweet;
}

@property (nonatomic, readonly) NSString *tweetID;
@property (nonatomic, copy) NSString *nick;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) ResponseTweetType tweetType;
@property (nonatomic, retain) Tweet *souceTweet;

- (NSAttributedString *)formattedTweet;

@end
