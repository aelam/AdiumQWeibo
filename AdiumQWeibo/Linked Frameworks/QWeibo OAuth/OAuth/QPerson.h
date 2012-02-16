//
//  QPerson.h
//  AdiumQWeibo
//
//  Created by Ryan Wang Wang on 12-2-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//



@interface QPerson : NSObject {
    BOOL        _isMyBlack;
    BOOL        _isMyFans;
    BOOL        _isMyIdol;
    NSDate      *_birth;
    NSString    *_cityCode;
    NSString    *_countryCode;
    NSString    *_edu;
    NSString    *_email;
    int         _fansNum;
    NSString    *_head;
    int         _idolNum;
    NSString    *_introduction;
    BOOL        _isEnt;
    BOOL        _isVIP;
    NSString    *_location;
    NSString    *_name;
    NSString    *_nick;
    NSString    *_openID;
    NSString    *_provinceCode;
    BOOL        _sex;
    NSString    *_tag;
    int         _tweetNum;
    NSString    *_verifyInfo;

    
}

@property (assign) BOOL isMyBlack;
@property (assign) BOOL isMyFans;
@property (assign) BOOL isMyIdol;
@property (retain) NSDate *birth;
@property (copy) NSString *cityCode;
@property (copy) NSString *countryCode;
@property (copy) NSString *edu;
@property (copy) NSString *email;
@property (assign) int fansNum;
@property (copy) NSString *head;
@property (assign) int idolNum;
@property (copy) NSString *introduction;
@property (assign) BOOL isEnt;
@property (assign) BOOL isVIP;
@property (copy) NSString *location;
@property (copy) NSString *name;
@property (copy) NSString *nick;
@property (copy) NSString *openID;
@property (copy) NSString *provinceCode;
@property (assign) BOOL sex;
@property (copy) NSString *tag;
@property (assign) int tweetNum;
@property (copy) NSString *verifyInfo;

@end
