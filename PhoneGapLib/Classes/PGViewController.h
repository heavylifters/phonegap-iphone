/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 * Copyright (c) 2010-11, HeavyLifters Network Ltd.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "PGCommand.h"

@interface PGViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView *_webView;
	NSArray* _supportedOrientations;
	NSDictionary *_configuration;
	NSDictionary *_settings;
	NSMutableDictionary *_commands;
}

@property (nonatomic, readonly, retain) NSDictionary *configuration;
@property (nonatomic, readonly, retain) NSDictionary *settings;
@property (nonatomic, retain) NSArray *supportedOrientations;

- (void) preloadCommands;
- (PGCommand *) commandNamed: (NSString *)className;

- (NSString *) pathForResource: (NSString *)resource;
- (NSString *) stringByEvaluatingJavaScriptFromString: (NSString *)javascript;

+ (NSDictionary *) getBundlePlist: (NSString *)plistName;
+ (NSString *) phoneGapVersion;

// methods that subclasses are encouraged to override
- (void) loadConfiguration;
- (void) loadSettings;
- (NSBundle *) resourceBundle;
- (NSString *) wwwFolderName;

@end
