//
//  PGCommand.h
//  PhoneGap
//
//  Created by Michael Nachbaur on 13/04/09.
//  Copyright 2009 Decaf Ninja Software. All rights reserved.
//  Copyright (c) 2010-11, HeavyLifters Network Ltd.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PGViewController;

@interface PGCommand : NSObject
{
	PGViewController *_controller;
    NSDictionary *_settings;
}

@property (nonatomic, readonly, assign) PGViewController *controller;
@property (nonatomic, readonly, retain) NSDictionary *settings;

// -initWithController:settings: is the designated initializer
- (id) initWithController: (PGViewController *)vc settings: (NSDictionary *)settings_;
- (id) initWithController: (PGViewController *)vc;

- (NSString *) stringByEvaluatingJavaScriptFromString: (NSString *)javascript;

- (void) clearCaches;

- (NSString *) wwwFolderName;
- (NSString *) pathForResource: (NSString *)resource;

@end
