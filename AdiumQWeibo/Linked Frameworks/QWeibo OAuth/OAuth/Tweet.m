//
//  Tweet.m
//  AdiumQWeibo
//
//  Created by Ryan Wang Wang on 12-2-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Tweet.h"

@implementation Tweet

@synthesize tweetID = _tweetID;
@synthesize nick = _nick;
@synthesize name = _name;
@synthesize timestamp = _timestamp;
@synthesize tweetType = _tweetType;
@synthesize souceTweet = _souceTweet;


- (NSAttributedString *)formattedTweet {
    
    return nil;
}

- (void)dealloc {
    [_tweetID release];
    [_nick release];
    [_name release];
    [super dealloc];
}

@end
