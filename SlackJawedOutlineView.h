//
//  SlackJawedOutlineView.h
//  TreeArchive
//
//  Created by Kevin Doughty on 7/27/11.
//  Copyright 2011 Kevin Doughty. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SlackJawedOutlineView : NSOutlineView {
	NSMutableSet *expandedObjects;
	BOOL blockExpandOrCollapseFromPropagatingBackUp;
}
@property (retain) NSSet *expandedObjects;

-(void) expandObject:(id)theObject;
-(void) collapseObject:(id)theObject;
-(void) syncExpandedObjects:(NSSet*)theExpandedObjects;
@end
