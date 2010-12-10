/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 * Copyright (c) 2010, IBM Corporation
 * Copyright (c) 2010-11, HeavyLifters Network Ltd.
 */

#import <UIKit/UIKit.h>
#import "JSON/JSON.h"
#import "PGAppDelegate.h"
#import "PGViewController.h"
#import "InvokedUrlCommand.h"
#import "Contact.h"

@implementation PGAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize activityView;
@synthesize invokedURL;

- (NSString*) applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

/**
 * This is main kick off after the app inits, the views and Settings are setup here.
 */
// - (void)applicationDidFinishLaunching:(UIApplication *)application
- (BOOL) application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{	
	viewController = [[PGViewController alloc] init];

	// read from UISupportedInterfaceOrientations (or UISupportedInterfaceOrientations~iPad, if its iPad) from -Info.plist
	NSArray* supportedOrientations = [viewController supportedOrientations];
	
	// The first item in the supportedOrientations array is the start orientation (guaranteed to be at least Portrait)
	[[UIApplication sharedApplication] setStatusBarOrientation: [[supportedOrientations objectAtIndex: 0] intValue]];
	
	self.window = [[[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]] autorelease];
	
	// This has been moved from the webViewDidStartLoad because invokedURL never had been set
	// from handleOpenURL - so I've changed this method from using didFinishLaunching to
	// didFinishLaunchingWithOptions to capture the original url that launched the app
	NSArray *keyArray = [launchOptions allKeys];
	if ([launchOptions objectForKey: [keyArray objectAtIndex: 0]]) {
		NSURL *url = [launchOptions objectForKey: [keyArray objectAtIndex: 0]];
		invokedURL = url;
		if ([invokedURL isKindOfClass:[NSURL class]])
		{
			NSLog(@"URL = %@", [invokedURL absoluteURL]);
			// Determine the URL used to invoke this application.
			// Described in http://iphonedevelopertips.com/cocoa/launching-your-own-application-via-a-custom-url-scheme.html
			if ([[invokedURL scheme] isEqualToString:[self appURLScheme]]) {
				InvokedUrlCommand* iuc = [[InvokedUrlCommand newFromUrl:invokedURL] autorelease];
			
				// NSLog(@"Arguments: %@", iuc.arguments);
			
				NSString *optionsString = [[NSString alloc] initWithFormat: @"var Invoke_params=%@;", [iuc.options JSONFragment]];
				[viewController stringByEvaluatingJavaScriptFromString: optionsString];
				[optionsString release];
			}
		}
	}
	
	[window addSubview: [viewController view]];

	/*
	 * imageView - is the Default loading screen, it stay up until the app and UIWebView (WebKit) has completly loaded.
	 * You can change this image by swapping out the Default.png file within the resource folder.
	 */
	UIImage* image = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Default" ofType: @"png"]];
	imageView = [[UIImageView alloc] initWithImage: image];
	[image release];
	
    imageView.tag = 1;
	[window addSubview:imageView];
	
	/*
	 * The Activity View is the top spinning throbber in the status/battery bar. We init it with the default Grey Style.
	 *
	 *	 whiteLarge = UIActivityIndicatorViewStyleWhiteLarge
	 *	 white      = UIActivityIndicatorViewStyleWhite
	 *	 gray       = UIActivityIndicatorViewStyleGray
	 *
	 */
    NSString *topActivityIndicator = [[viewController settings] objectForKey: @"TopActivityIndicator"];
    UIActivityIndicatorViewStyle topActivityIndicatorStyle = UIActivityIndicatorViewStyleGray;
	if (topActivityIndicator) {
		if ([@"whiteLarge" isEqualToString: topActivityIndicator]) {
			topActivityIndicatorStyle = UIActivityIndicatorViewStyleWhiteLarge;
		} else if ([@"white" isEqualToString: topActivityIndicator]) {
			topActivityIndicatorStyle = UIActivityIndicatorViewStyleWhite;
		} else if ([@"gray" isEqualToString: topActivityIndicator]) {
			topActivityIndicatorStyle = UIActivityIndicatorViewStyleGray;
		}
	}
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: topActivityIndicatorStyle];
    activityView.tag = 2;
    [window addSubview: activityView];
    [activityView startAnimating];
	
	[window makeKeyAndVisible];
	
	return YES;
}

- (NSString*) appURLScheme
{
	// The info.plist contains this structure:
	//<key>CFBundleURLTypes</key>
	// <array>
	//		<dict>
	//			<key>CFBundleURLSchemes</key>
	//			<array>
	//				<string>yourscheme</string>
	//			</array>
	//			<key>CFBundleURLName</key>
	//			<string>YourbundleURLName</string>
	//		</dict>
	// </array>
	
	NSString* URLScheme = nil;
	
    NSArray *URLTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    if(URLTypes != nil ) {
		NSDictionary* dict = [URLTypes objectAtIndex:0];
		if(dict != nil ) {
			NSArray* URLSchemes = [dict objectForKey:@"CFBundleURLSchemes"];
			if( URLSchemes != nil ) {    
				URLScheme = [URLSchemes objectAtIndex:0];
			}
		}
	}
	
	return URLScheme;
}

/**
 Called when the webview finishes loading.  This stops the activity view and closes the imageview
 */
- (void) webViewDidFinishLoad: (UIWebView *)theWebView {
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	activityView.hidden = YES;	
	
	imageView.hidden = YES;
	
	[window bringSubviewToFront:viewController.view];
}

/*
 This method lets your application know that it is about to be terminated and purged from memory entirely
*/
- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    // clean up any Contact objects
	// FIXME: remove this, it's totally unnecessary
    [[Contact class] releaseDefaults];

}

/*
 This method is called to let your application know that it is about to move from the active to inactive state.
 You should use this method to pause ongoing tasks, disable timer, ...
*/
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"%@",@"applicationWillResignActive");

    NSString* jsString = 
    @"(function(){"
    "var e = document.createEvent('Events');"
    "e.initEvent('pause');"
    "document.dispatchEvent(e);"
    "})();";

    [viewController stringByEvaluatingJavaScriptFromString:jsString];

}

/*
 In iOS 4.0 and later, this method is called as part of the transition from the background to the inactive state. 
 You can use this method to undo many of the changes you made to your application upon entering the background.
 invariably followed by applicationDidBecomeActive
*/
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"%@",@"applicationWillEnterForeground");

    NSString* jsString = 
    @"(function(){"
    "var e = document.createEvent('Events');"
    "e.initEvent('resume');"
    "document.dispatchEvent(e);"
    "})();";

    [viewController stringByEvaluatingJavaScriptFromString:jsString];

}

// This method is called to let your application know that it moved from the inactive to active state. 
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"%@",@"applicationDidBecomeActive");
}

/*
 In iOS 4.0 and later, this method is called instead of the applicationWillTerminate: method 
 when the user quits an application that supports background execution.
 */
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"%@",@"applicationDidEnterBackground");
}



- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSLog(@"In handleOpenURL");
    if (!url) { return NO; }

    NSLog(@"URL = %@", [url absoluteURL]);
    invokedURL = url;

    return YES;
}

- (void)dealloc
{
	[imageView release];
	[viewController release];
    [activityView release];
	[window release];
	[invokedURL release];
	
	[super dealloc];
}


@end
