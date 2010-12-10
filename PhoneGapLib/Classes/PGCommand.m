//
//  PGCommand.m
//  PhoneGap
//
//  Created by Michael Nachbaur on 13/04/09.
//  Copyright 2009 Decaf Ninja Software. All rights reserved.
//  Copyright (c) 2010-11, HeavyLifters Network Ltd.
//

#import "PGCommand.h"

@implementation PGCommand

@synthesize controller=_controller;
@synthesize settings=_settings;

- (PGCommand *) initWithController: (PGViewController *)vc settings: (NSDictionary *)settings_
{
    self = [super init];
    if (self) {
		_controller = vc;
		_settings = [settings_ retain];
	}
    return self;
}

- (PGCommand *) initWithController: (PGViewController *)vc
{
    self = [self initWithController: vc settings: nil];
    return self;
}

- (void) dealloc
{
	_controller = nil;
    [_settings release]; _settings = nil;
    [super dealloc];
}

- (NSString *) wwwFolderName
{
	return [[self controller] wwwFolderName];
}

- (NSString *) pathForResource: (NSString *)resource
{
	return [[self controller] pathForResource: resource];
}

- (NSString *) stringByEvaluatingJavaScriptFromString: (NSString *)javascript
{
	return [[self controller] stringByEvaluatingJavaScriptFromString: javascript];
}

- (void) clearCaches
{
	// override
}

@end