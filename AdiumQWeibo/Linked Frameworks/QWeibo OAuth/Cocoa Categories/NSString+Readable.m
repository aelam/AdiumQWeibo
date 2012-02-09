//
//  NSString+Readable.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-18.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "NSString+Readable.h"

NSString * EmptyString(NSString *string) {
    if(string == nil) return @"";
    
    return string;
}

@implementation NSString (Readable)

- (NSString *)readableTimestamp:(double)timestamp {
    double now = (double)time(NULL);
    
    double gap = now - timestamp;
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"YY-MM-dd HH:mm:dd"];

    if (gap < 0) {
        // 未来的时间点
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        NSString *result = [formatter stringFromDate:date];
        return result;
    } else if ( 0<= gap <= 60) {
        // 0 - 60 秒
        return [NSString stringWithFormat:@"%d秒前",gap];
    } else if( 60 < gap <= 60 * 60) {
        // 60秒 - 60分钟
        return [NSString stringWithFormat:@"%d分钟前",gap / 60];
    } else {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        NSString *result = [formatter stringFromDate:date];
        return result;
    }
}


@end

@implementation NSDate (Utilities)

- (NSDate *)dateAtMidnight {
	// Initialize the calendar and flags.
	NSCalendar *calendar = [NSCalendar currentCalendar];
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |
	NSDayCalendarUnit | NSWeekdayCalendarUnit;
    
	// Set date's hour/minute/second to zero.
	NSDateComponents *comps = [calendar components:unitFlags fromDate:self];
	[comps setHour:0];
	[comps setMinute:0];
	[comps setSecond:0];
	return [calendar dateFromComponents:comps];
}
@end

