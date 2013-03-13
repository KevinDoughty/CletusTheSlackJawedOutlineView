//
//  SlackJawedContext.h
//  TreeArchive
//
//  Created by Kevin Doughty on 7/26/11.
//  Copyright 2011 Kevin Doughty. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SlackJawedNode.h"
@class SlackJawedOutlineView;
@interface SlackJawedContext : SlackJawedNode {
	NSUndoManager *undoManager;
	NSMutableSet *expandedObjects;
	NSArray *selectionIndexPaths;
}


@property (assign) NSUndoManager *undoManager;
@property (copy) NSSet *expandedObjects;
@property (copy) NSArray *selectionIndexPaths;




@end
