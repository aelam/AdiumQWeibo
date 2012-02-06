//
//  UnitTest.m
//  UnitTest
//
//  Created by Ryan Wang on 12-2-6.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "UnitTest.h"
#import "RegexKitLite.h"

@implementation UnitTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
//    STFail(@"Unit tests are not implemented yet in UnitTest");
//    [AdiumQWeiboEngine attributedTweetFromTweetDictionary:nil];
}

- (void)_testParseUsername {
    static NSString *usernameCharacters = nil;
//    static NSString *topicCharacters = nil;
    
    if (usernameCharacters == nil) {
        usernameCharacters = [@"(?<=@)[\\w-]{2,40}" retain];
    }
    //    NSString *originText = [json objectForKey:@"origtext"];
    NSString *originText = @"@hello eeeedcdcd  @lunwang-kkk dcdcaaaasdcd @@@ddddjjjkj";    
    [SenTestLog testLogWithFormat:@"originText : %@\n",originText];
    
    NSString *t1 = [originText stringByReplacingOccurrencesOfRegex:@"(?<=@)[\\w-]{2,40}" withString:@"replacement"];
    [SenTestLog testLogWithFormat:@"originText2 : %@\n",t1];

}

- (void)_testTopic {
    NSString *originText = @"##dsfsdf# fdsfdsfds #dfdsfsdfds# fdfdfdfd";    
    [SenTestLog testLogWithFormat:@"originText : %@\n",originText];
    
    NSString *t1 = [originText stringByReplacingOccurrencesOfRegex:@"#([^\\#|.]+)#" /*@"#[\\s\\S]+?#"*/ withString:@"MM"];
    [SenTestLog testLogWithFormat:@"originText2 : %@\n",t1];    
}

- (void)testEmotions {
    NSString *originText = @"/坏笑fsdfsdf/撇嘴hi hello";    
    [SenTestLog testLogWithFormat:@"originText : %@\n",originText];
    
    
    NSString *facePath = @"/Users/ryan/Documents/AdiumQWeibo/AdiumQWeibo/Resources/emotions/face.plist";
    NSDictionary *facePairs = [NSDictionary dictionaryWithContentsOfFile:facePath];

    NSString *temp1 = [[facePairs allKeys] componentsJoinedByString:@"|/"];    
    NSString *regex = [NSString stringWithFormat:@"/%@",temp1];
    
    // /坏笑|/撇嘴
    NSString* r = [originText stringByReplacingOccurrencesOfRegex:regex usingBlock:^NSString *(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        for(int i = 0; i < captureCount;i++) {
            [SenTestLog testLogWithFormat:@"originText2 : %@\n",capturedStrings[i]];  
            NSString *temp = [capturedStrings[i] stringByReplacingOccurrencesOfString:@"/" withString:@""];
            
            [SenTestLog testLogWithFormat:@"facePairs-k: %@\n",temp]; 
            [SenTestLog testLogWithFormat:@"facePairs2 : %@\n",[facePairs objectForKey:temp]];                
            
        }
        return @"[--]";
    }];
    
    [SenTestLog testLogWithFormat:@"originText3 : %@\n",r];                
    
//    NSString *t1 = [originText stringByReplacingOccurrencesOfRegex:@"/[坏笑|批嘴]" /*@"#[\\s\\S]+?#"*/ withString:@"MM"];
//    [SenTestLog testLogWithFormat:@"originText2 : %@\n",t1];    
}



@end
