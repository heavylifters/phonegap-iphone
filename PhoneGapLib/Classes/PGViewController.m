/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 * Copyright (c) 2010-11, HeavyLifters Network Ltd.
 */

#import "PGViewController.h"
#import "InvokedUrlCommand.h"
#import "JSON.h"
#import "Location.h"

@interface PGViewController ()
- (void) loadSupportedOrientations;
- (NSString *) startPage;
- (NSDictionary *) deviceProperties;
+ (void) loadDefaultSupportedOrientations;
+ (NSDictionary *) getBundlePlist: (NSString *)plistName;
+ (NSString *) phoneGapVersion;
+ (NSArray *) parseInterfaceOrientations: (NSArray *)orientations;
@end

@implementation PGViewController

static NSArray *_defaultSupportedOrientations;

@synthesize supportedOrientations=_supportedOrientations;

+ (void) initialize
{
	if (self == [PGViewController class]) {
		[self loadDefaultSupportedOrientations];
	}
}

- (id) init
{
	self = [self initWithNibName: nil bundle: nil];
	return self;
}

- (id) initWithNibName: (NSString *)nibNameOrNil bundle: (NSBundle *)nibBundleOrNil;
{
    if (self = [super initWithNibName: nil bundle: nil]) {
		_configuration = nil;
		_settings = nil;
		_supportedOrientations = nil;
		_commands = nil;
		_webView = nil;
		[self loadSupportedOrientations];
	}
	return self;
}

- (void) dealloc
{
	[_configuration release]; _configuration = nil;
	[_commands release]; _commands = nil;
	[_settings release]; _settings = nil;
	[_webView release]; _webView = nil;
	[_supportedOrientations release]; _supportedOrientations = nil;
	[super dealloc];
}

- (void) loadConfiguration
{
	_configuration = [[NSDictionary alloc] initWithDictionary: [[self class] getBundlePlist: @"PhoneGap"]];
}

- (void) loadSettings
{
	_settings = [[NSDictionary alloc] initWithDictionary: [[self class] getBundlePlist: @"Settings"]];
}

- (NSDictionary *) configuration
{
	if (_configuration == nil) {
		[self loadConfiguration];
	}
	return _configuration;
}

- (NSDictionary *) settings
{
	if (_settings == nil) {
		[self loadSettings];
	}
	return _settings;
}

- (void) loadSupportedOrientations
{
	_supportedOrientations = [_defaultSupportedOrientations retain];
}

- (void) initializeCommands
{
	[_commands release];
	_commands = [[NSMutableDictionary alloc] initWithCapacity: 20];
}

- (void) preloadCommands
{
	/*
	 * Fire up the GPS Service right away as it takes a moment for data to come back.
	 */
	NSNumber *useLocation = [[self configuration] objectForKey: @"UseLocation"];
	if ([useLocation boolValue]) {
		[(Location *)[self commandNamed: @"Location"] startLocation: nil withDict: nil];
	}
}

- (CGRect) webViewBounds
{
	return [[self view] bounds];
}

- (void) loadWebView
{
	[_webView release];
	_webView = [[UIWebView alloc] initWithFrame: [self webViewBounds]];
	[_webView setAutoresizingMask: (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
	
	[[self view] setAutoresizesSubviews: YES];
	[[self view] addSubview: _webView];
	[_webView setDelegate: self];
}

- (void) loadRequestIntoWebView
{
	NSString *startPage = [self startPage];
	NSURL *appURL = [NSURL URLWithString: startPage];
	if (![appURL scheme]) {
		appURL = [NSURL fileURLWithPath: [self pathForResource: [self startPage]]];
	}
	
    NSURLRequest *appReq = [NSURLRequest requestWithURL: appURL
											cachePolicy: NSURLRequestUseProtocolCachePolicy
										timeoutInterval: 20.0];
	[_webView loadRequest: appReq];
	
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30000
    NSNumber *detectNumber = [[self configuration] objectForKey: @"DetectPhoneNumber"];
	if (detectNumber) [_webView setDetectsPhoneNumbers: [detectNumber boolValue]];
#endif
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self initializeCommands];
	[self preloadCommands];
	
	/*
	 * webView
	 * This is where we define the inital instance of the browser (WebKit) and give it a starting url/file.
	 */
	[self loadWebView];
	[self loadRequestIntoWebView];
}

- (void) viewDidUnload
{
	[_webView release]; _webView = nil;
	[_commands release]; _commands = nil;
	[super viewDidUnload];
}

#pragma mark -
#pragma mark Orientation support

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation 
{
    // First ask the webview via JS if it wants to support the new orientation -jm
    int i = 0;
     
    switch (interfaceOrientation){
 
        case UIInterfaceOrientationPortraitUpsideDown:
            i = 180;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            i = -90;
            break;
        case UIInterfaceOrientationLandscapeRight:
            i = 90;
            break;
        default:
        case UIInterfaceOrientationPortrait:
            // noop
            break;
    }
     
    NSString* jsCall = [ NSString stringWithFormat:@"shouldRotateToOrientation(%d);",i];
    NSString* res = [self stringByEvaluatingJavaScriptFromString:jsCall];
     
    if([res length] > 0)
    {
        return [res boolValue];
    }
     
    // if js did not handle the new orientation ( no return value ) we will look it up in the plist -jm
     
    // autorotate if only more than 1 orientation supported
    // default return value is NO! -jm
    return ([self.supportedOrientations count] > 0) && [self.supportedOrientations containsObject: [NSNumber numberWithInt:interfaceOrientation]];
}

/**
 Called by UIKit when the device starts to rotate to a new orientation.  This fires the \c setOrientation
 method on the Orientation object in JavaScript.  Look at the JavaScript documentation for more information.
 */
- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
{
    int i = 0;
	
	switch (self.interfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			i = 0;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			i = 180;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			i = -90;
			break;
		case UIInterfaceOrientationLandscapeRight:
			i = 90;
			break;
		default:
			break;
	}
	
	NSString* jsCallback = [NSString stringWithFormat:@"window.__defineGetter__('orientation',function(){return %d;});window.onorientationchange();",i];
	[self stringByEvaluatingJavaScriptFromString:jsCallback];
	 
}

/**
 Returns a PGCommand object, based on its name.  If one exists already, it is returned.
 */
- (PGCommand *) commandNamed: (NSString *)className
{
	id obj = [_commands objectForKey: className];
	if (obj == nil) {
		Class clazz = NSClassFromString(className);
		if ([clazz isSubclassOfClass: [PGCommand class]]) {
			// attempt to load the settings for this command class
			NSDictionary* commandSettings = [[self configuration] objectForKey: className];
			
			obj = commandSettings ?
			[[clazz alloc] initWithController: self settings: commandSettings] :
			[[clazz alloc] initWithController: self];
			
			[_commands setObject: obj forKey: className];
			[obj release];
		}
	}
    return obj;
}

- (NSString *) stringByEvaluatingJavaScriptFromString: (NSString *)javascript;
{
	return [_webView stringByEvaluatingJavaScriptFromString: javascript];
}

- (BOOL) execute: (InvokedUrlCommand*)command
{
	if (command.className == nil || command.methodName == nil) {
		return NO;
	}
	
	// Fetch an instance of this class
	PGCommand* obj = [self commandNamed: command.className];
	
	// construct the fill method name to ammend the second argument.
	SEL sel = NSSelectorFromString([NSString stringWithFormat: @"%@:withDict:", command.methodName]);
	if ([obj respondsToSelector: sel]) {
		[obj performSelector: sel withObject: command.arguments withObject: command.options];
	} else {
		// There's no method to call, so throw an error.
		NSLog(@"Class method '%@' not defined in class '%@'", NSStringFromSelector(sel), command.className);
		[NSException raise: NSInternalInconsistencyException
					format: @"Class method '%@' not defined against class '%@'.", NSStringFromSelector(sel), command.className];
	}
	
	return YES;
}

#pragma mark -
#pragma mark UIWebViewDelegate methods

/**
 When web application loads Add stuff to the DOM, mainly the user-defined settings from the Settings.plist file, and
 the device's data such as device ID, platform version, etc.
 */
- (void) webViewDidStartLoad: (UIWebView *)theWebView 
{
}

/**
 Called when the webview finishes loading.  This stops the activity view and closes the imageview
 */
- (void) webViewDidFinishLoad: (UIWebView *)theWebView
{
	/*
	 * Hide the Top Activity THROBER in the Battery Bar
	 */
	
    NSDictionary *deviceProperties = [self deviceProperties];
    NSMutableString *result = [[NSMutableString alloc] initWithFormat: @"DeviceInfo = %@;", [deviceProperties JSONFragment]];
    
    /* Settings.plist
	 * Read the optional Settings.plist file and push these user-defined settings down into the web application.
	 * This can be useful for supplying build-time configuration variables down to the app to change its behaviour,
     * such as specifying Full / Lite version, or localization (English vs German, for instance).
	 */
	
	NSDictionary *settings = [self settings];
	
    if ([settings respondsToSelector: @selector(JSONFragment)]) {
        [result appendFormat: @"\nwindow.Settings = %@;", [settings JSONFragment]];
    }
	
    NSLog(@"Device initialization: %@", result);
    [theWebView stringByEvaluatingJavaScriptFromString: result];
	[result release];
}


/**
 * Fail Loading With Error
 * Error - If the webpage failed to load display an error with the reson.
 */
- (void) webView: (UIWebView *)webView didFailLoadWithError: (NSError *)error
{
    NSLog(@"Failed to load webpage with error: %@", [error localizedDescription]);
	// if ([error code] != NSURLErrorCancelled) alert([error localizedDescription]);
}


/**
 * Start Loading Request
 * This is where most of the magic happens... We take the request(s) and process the response.
 * From here we can re direct links and other protocalls to different internal methods.
 */
- (BOOL) webView: (UIWebView *)theWebView shouldStartLoadWithRequest: (NSURLRequest *)request navigationType: (UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	
    /*
     * Get Command and Options From URL
     * We are looking for URLS that match gap://<Class>.<command>/[<arguments>][?<dictionary>]
     * We have to strip off the leading slash for the options.
     */
	if ([[url scheme] isEqualToString:@"gap"]) {
		
		InvokedUrlCommand* iuc = [[InvokedUrlCommand newFromUrl: url] autorelease];
        
		// Tell the JS code that we've gotten this command, and we're ready for another
        [theWebView stringByEvaluatingJavaScriptFromString: @"PhoneGap.queue.ready = true;"];
		
		// Check to see if we are provided a class:method style command.
		[self execute: iuc];
		
		return NO;
	}
    
    /*
     * If a URL is being loaded that's a file/http/https URL, just load it internally
     */
    else if ([url isFileURL])
    {
        return YES;
    }
	else if ( [ [url scheme] isEqualToString:@"http"] || [ [url scheme] isEqualToString:@"https"] ) 
	{
		if(navigationType == UIWebViewNavigationTypeOther)
		{
			[[UIApplication sharedApplication] openURL:url];
			return NO;
		}
		else 
		{
			return YES;
		}
	}
    
    /*
     * We don't have a PhoneGap or web/local request, load it in the main Safari browser.
	 * pass this to the application to handle.  Could be a mailto:dude@duderanch.com or a tel:55555555 or sms:55555555 facetime:55555555
     */
    else
    {
        // NSLog(@"PGViewController -webView:shouldStartLoadWithRequest:navigationType: Received Unhandled URL %@", url);
        [[UIApplication sharedApplication] openURL: url];
        return NO;
	}
	
	return YES;
}

- (NSDictionary *) deviceProperties
{
	UIDevice *device = [UIDevice currentDevice];
    return [NSDictionary dictionaryWithObjectsAndKeys:
			[device model], @"platform",
			[device systemVersion], @"version",
			[device uniqueIdentifier], @"uuid",
			[device name], @"name",
			[[self class] phoneGapVersion], @"gap",
			nil];
}

#pragma mark -
#pragma mark Web Content

- (NSBundle *) resourceBundle
{
	return [NSBundle mainBundle];
}

- (NSString *) wwwFolderName
{
	return @"www";
}

- (NSString *) startPage
{
	return @"index.html";
}

- (NSString *) pathForResource: (NSString *)resource
{
    NSMutableArray *directoryParts = [NSMutableArray arrayWithArray: [resource componentsSeparatedByString: @"/"]];
    NSString *filename = [directoryParts lastObject];
	// This change is important, it fixes a bug where two // can end up
	// in the URL causing problems when using relative URLs
    if (filename) [directoryParts removeLastObject];
	NSString *directoryStr = [self wwwFolderName];
	for (NSString *comp in directoryParts) {
		directoryStr = [directoryStr stringByAppendingPathComponent: comp];
	}
    return [[self resourceBundle] pathForResource: filename
										   ofType: @""
									  inDirectory: directoryStr];
}

#pragma mark -
#pragma mark Class methods

/**
 Returns the contents of the named plist bundle, loaded as a dictionary object
 */
+ (NSDictionary *) getBundlePlist: (NSString *)plistName
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource: plistName ofType: @"plist"];
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath: plistPath];
	return (NSDictionary *)[NSPropertyListSerialization propertyListWithData: plistXML options: 0 format: NULL error: NULL];
}

/**
 Returns the current version of phoneGap as read from the VERSION file
 This only touches the filesystem once and stores the result in the class variable gapVersion
 */
static NSString *gapVersion;
+ (NSString *) phoneGapVersion
{
	if (gapVersion == nil) {
		NSString *path = [[NSBundle mainBundle] pathForResource: @"VERSION" ofType: nil];
		gapVersion = path ? [[NSString alloc] initWithContentsOfFile: path
															encoding: NSUTF8StringEncoding
															   error: NULL] : @"unknown";
	}
	
	return gapVersion;
}


+ (NSArray *) parseInterfaceOrientations: (NSArray *)orientations
{
	NSMutableArray* result = [[[NSMutableArray alloc] init] autorelease];
	if (orientations) {
		for (NSString *orientationString in orientations) {
			if ([@"UIInterfaceOrientationPortrait" isEqualToString: orientationString]) {
				[result addObject: [NSNumber numberWithInt: UIInterfaceOrientationPortrait]];
			} else if ([@"UIInterfaceOrientationPortraitUpsideDown" isEqualToString: orientationString]) {
				[result addObject: [NSNumber numberWithInt: UIInterfaceOrientationPortraitUpsideDown]];
			} else if ([@"UIInterfaceOrientationLandscapeLeft" isEqualToString: orientationString]) {
				[result addObject: [NSNumber numberWithInt: UIInterfaceOrientationLandscapeLeft]];
			} else if ([@"UIInterfaceOrientationLandscapeRight" isEqualToString: orientationString]) {
				[result addObject: [NSNumber numberWithInt: UIInterfaceOrientationLandscapeRight]];
			}
		}
	}
	if ([result count] == 0) {
		[result addObject: [NSNumber numberWithInt: UIInterfaceOrientationPortrait]];
	}
	return result;
}

+ (void) loadDefaultSupportedOrientations
{
	// read from UISupportedInterfaceOrientations (or UISupportedInterfaceOrientations~iPad, if its iPad) from -Info.plist
	NSArray *orr = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"UISupportedInterfaceOrientations"];
	_defaultSupportedOrientations = [[self parseInterfaceOrientations: orr] retain];
}

@end
