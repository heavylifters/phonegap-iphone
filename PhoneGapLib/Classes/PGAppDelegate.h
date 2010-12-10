/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 * Copyright (c) 2010, IBM Corporation
 * Copyright (c) 2010-11, HeavyLifters Network Ltd.
 */

#import <UIKit/UIKit.h>

@class InvokedUrlCommand;
@class PGViewController;
@class Sound;
@class Contacts;

@interface PGAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window;
	PGViewController *viewController;
	
	UIImageView *imageView;
	UIActivityIndicatorView *activityView;
	
    UIInterfaceOrientation orientationType;
    NSURL *invokedURL;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) PGViewController *viewController;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, retain) NSURL *invokedURL;

- (NSString*) appURLScheme;

- (NSString*) applicationDocumentsDirectory;

@end
