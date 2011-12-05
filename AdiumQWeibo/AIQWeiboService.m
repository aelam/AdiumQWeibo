//
//  AIQWeiboService.m
//  AdiumQWeibo
//
//  Created by Ryan Wang on 11-12-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AIQWeiboService.h"
#import "AIQWeiboAccountViewController.h"
#import "AIQWeiboAccount.h"
#import <Adium/AISharedAdium.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>


#define SERVICE_PROVIDER    @"QWeibo"

@implementation AIQWeiboService

- (Class)accountClass
{
	return [AIQWeiboAccount class];
}

- (AIQWeiboAccountViewController *)accountViewController
{
	return [AIQWeiboAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView
{
	return nil;
}

// Service description
- (NSString *)serviceCodeUniqueID{
	return SERVICE_PROVIDER;
}
- (NSString *)serviceID{
	return SERVICE_PROVIDER;
}
- (NSString *)serviceClass{
	return SERVICE_PROVIDER;
}
- (NSString *)shortDescription{
	return SERVICE_PROVIDER;
}
- (NSString *)longDescription{
	return SERVICE_PROVIDER;
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"];
}
- (NSUInteger)allowedLength{
	return 999;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (BOOL)supportsProxySettings{
	return NO;
}
- (void)registerStatuses{
	[adium.statusController registerStatus:STATUS_NAME_AVAILABLE
                           withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
                                    ofType:AIAvailableStatusType
                                forService:self];
}

- (BOOL)requiresPassword
{
	return NO;
}

- (BOOL)isSocialNetworkingService
{
	return YES;
}

/*!
 * @brief Default icon
 *
 * Service Icon packs should always include images for all the built-in Adium services.  This method allows external
 * service plugins to specify an image which will be used when the service icon pack does not specify one.  It will
 * also be useful if new services are added to Adium itself after a significant number of Service Icon packs exist
 * which do not yet have an image for this service.  If the active Service Icon pack provides an image for this service,
 * this method will not be called.
 *
 * The service should _not_ cache this icon internally; multiple calls should return unique NSImage objects.
 *
 * @param iconType The AIServiceIconType of the icon to return. This specifies the desired size of the icon.
 * @return NSImage to use for this service by default
 */
- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType
{
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [NSImage imageNamed:@"qweibo-small" forClass:[self class] loadLazily:YES];
	} else {
		return [NSImage imageNamed:@"qweibo" forClass:[self class] loadLazily:YES];
	}
}

/*!
 * @brief Path for default icon
 *
 * For use in message views, this is the path to a default icon as described above.
 *
 * @param iconType The AIServiceIconType of the icon to return.
 * @return The path to the image, otherwise nil.
 */
- (NSString *)pathForDefaultServiceIconOfType:(AIServiceIconType)iconType
{
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"qweibo-small"];
	} else {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"qweibo"];		
	}
}

@end
