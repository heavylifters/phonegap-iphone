//
//  DebugConsole.h
//  PhoneGap
//
//  Created by Michael Nachbaur on 14/03/09.
//  Copyright 2009 Decaf Ninja Software. All rights reserved.
//  Copyright (c) 2010-11, HeavyLifters Network Ltd.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PGCommand.h"

@interface DebugConsole : PGCommand {
}

- (void)log:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
