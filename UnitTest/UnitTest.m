//
//  UnitTest.m
//  UnitTest
//
//  Created by Ryan Wang on 11-12-19.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "UnitTest.h"
#import "AdiumQWeiboEngine+Helper.h"

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
    STAssertNil(nil, @"%@", [AdiumQWeiboEngine class]);
}

@end
