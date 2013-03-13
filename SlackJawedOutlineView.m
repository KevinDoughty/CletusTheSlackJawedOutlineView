//
//  SlackJawedOutlineView.m
//  TreeArchive
//
//  Created by Kevin Doughty on 7/27/11.
//  Copyright 2011 Kevin Doughty. All rights reserved.
//

#import "SlackJawedOutlineView.h"
#import "SlackJawedNode.h"
#import "SlackJawedContext.h"


@implementation SlackJawedOutlineView
@synthesize expandedObjects;
+(void)initialize {
    [self exposeBinding:@"expandedObjects"];
}
-(Class)valueClassForBinding:(NSString *)theBinding {
	if ([theBinding isEqualToString:@"expandedObjects"]) return [NSSet class];
	return [super valueClassForBinding:theBinding];
}


- (id)observedObjectForExpandedObjects {
	NSDictionary *theBindingInfo = [self infoForBinding:@"expandedObjects"];
	id theBoundObject = [theBindingInfo objectForKey:NSObservedObjectKey];
	return theBoundObject;
}
- (NSString *)observedKeyPathForExpandedObjects { 
	NSDictionary *theBindingInfo = [self infoForBinding:@"expandedObjects"];
	NSString *theBoundKeyPath = [theBindingInfo objectForKey:NSObservedKeyPathKey];
	return theBoundKeyPath;
}

#pragma mark expand / collapse

-(NSArray*) expandableDescendantItemsIncludingItem:(NSTreeNode*)theItem {
	NSMutableArray *theExpandables = nil;
	NSArray *theChildItems = [theItem childNodes];
	if ([theChildItems count]) { // The delegate can decide what is expandable or not, so this is not a sufficient check.
		theExpandables = [NSMutableArray arrayWithObject:theItem];
		for (NSTreeNode *theChildItem in theChildItems) {
			[theExpandables addObjectsFromArray:[self expandableDescendantItemsIncludingItem:theChildItem]];
		}
	}
	return theExpandables;
}
-(void) collapseItems:(NSArray*)theItems {
	NSArray *theNodes = [theItems valueForKey:@"representedObject"];
	NSMutableSet *theMutableSet = [self mutableSetValueForKey:@"expandedObjects"];
	[theMutableSet minusSet:[NSSet setWithArray:theNodes]];
}
-(void) expandItems:(NSArray*)theItems {
	NSArray *theNodes = [theItems valueForKey:@"representedObject"];
	NSMutableSet *theMutableSet = [self mutableSetValueForKey:@"expandedObjects"];
	[theMutableSet unionSet:[NSSet setWithArray:theNodes]];
}
-(void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
    
	BOOL isExpanded = [self isItemExpanded:item]; // not correct to check. If check fails, you might need to expand all children.
	[super collapseItem:item collapseChildren:collapseChildren];
	if (!blockExpandOrCollapseFromPropagatingBackUp) {
        if (collapseChildren) {
			[self collapseItems:[self expandableDescendantItemsIncludingItem:item]]; 
		} else {
			if (isExpanded) [self collapseObject:[item representedObject]];
		}
	}
}
-(void)expandItem:(id)item expandChildren:(BOOL)expandChildren {
	
	BOOL isExpanded = [self isItemExpanded:item]; // not correct to check. If check fails, you might need to expand all children.
	[super expandItem:item expandChildren:expandChildren];
	if (!blockExpandOrCollapseFromPropagatingBackUp) {
        if (expandChildren) {
			[self expandItems:[self expandableDescendantItemsIncludingItem:item]]; 
		} else {
			if (!isExpanded) [self expandObject:[item representedObject]]; 
		}
	}
}
-(void)collapseItem:(id)item {
    
	BOOL isExpanded = [self isItemExpanded:item];
	[super collapseItem:item collapseChildren:NO]; // I'm pretty sure expandItem just calls expandItem:expandChildren:NO, bypass my implementation to avoid unterminated 
	if (!blockExpandOrCollapseFromPropagatingBackUp) {
        if (isExpanded) [self collapseObject:[item representedObject]];
	}
}
-(void)expandItem:(id)item {
    
	BOOL isExpanded = [self isItemExpanded:item];
	[super expandItem:item expandChildren:NO]; // I'm pretty sure expandItem just calls expandItem:expandChildren:NO, bypass my implementation to avoid unterminated
	if (!blockExpandOrCollapseFromPropagatingBackUp) {
        if (!isExpanded) [self expandObject:[item representedObject]];
	}
}



-(void) expandObject:(id)theObject {
	if (theObject != nil) {
		if (![expandedObjects containsObject:theObject]) {
			[[[self observedObjectForExpandedObjects] mutableSetValueForKey:@"expandedObjects"] addObject:theObject];
		}
	}
}
-(void) collapseObject:(id)theObject {
	if (theObject != nil) {
		if ([expandedObjects containsObject:theObject]) {
			[[[self observedObjectForExpandedObjects] mutableSetValueForKey:@"expandedObjects"] removeObject:theObject];
		}
	}
}

-(void) addExpandedObjectsObject:(id)theObject {
	if (expandedObjects == nil) expandedObjects = [[NSMutableSet alloc] init];
	if (![expandedObjects containsObject:theObject]) {
        [expandedObjects addObject:theObject];
		[[[self observedObjectForExpandedObjects] mutableSetValueForKey:@"expandedObjects"] addObject:theObject];
	}
}
-(void) removeExpandedObjectsObject:(id)theObject {
	if ([expandedObjects containsObject:theObject]) {
        [expandedObjects removeObject:theObject];
		[[[self observedObjectForExpandedObjects] mutableSetValueForKey:@"expandedObjects"] removeObject:theObject];
	}
}
-(NSSet*)expandedObjects {
	if (expandedObjects == nil) expandedObjects = [[NSMutableSet alloc] init];
	return expandedObjects;
}
-(void)setExpandedObjects:(NSSet*)theExpandedObjects {
	[self syncExpandedObjects:theExpandedObjects];
    [expandedObjects release];
    expandedObjects = [[NSMutableSet alloc] initWithSet:theExpandedObjects];
}

-(void) syncExpandedObjects {
	[self syncExpandedObjects:[self expandedObjects]];
}
-(void) syncExpandedObjects:(NSSet*)theExpandedObjects {
	blockExpandOrCollapseFromPropagatingBackUp = YES;
	NSUInteger theRow = 0;
	for (theRow = 0; theRow < [self numberOfRows]; theRow++) { // Thank you Jonathan Dann // numberOfRows check is necessary every loop
		id theItem = [self itemAtRow:theRow];
		if ([theExpandedObjects containsObject:[theItem representedObject]]) [self expandItem:theItem];
		else [self collapseItem:theItem];
	}
	blockExpandOrCollapseFromPropagatingBackUp = NO;
}


-(void) syncExpandedObjectsToTreeNode:(NSTreeNode*)theTreeNode syncChildren:(BOOL)theSyncChildren {
    blockExpandOrCollapseFromPropagatingBackUp = YES;
    
    NSSet *theExpandedObjects = self.expandedObjects;
    if ([theExpandedObjects containsObject:[theTreeNode representedObject]]) [self expandItem:theTreeNode];
    else [self collapseItem:theTreeNode];
    
    if (theSyncChildren) {
        for (NSUInteger theRow = [self rowForItem:theTreeNode]+1; theRow < [self numberOfRows]; theRow++) { // Thank you Jonathan Dann // numberOfRows check is necessary every loop
            id theItem = [self itemAtRow:theRow];
            if ([theItem parentNode] == [theTreeNode parentNode]) break;
            else {
                if ([theExpandedObjects containsObject:[theItem representedObject]]) [self expandItem:theItem];
                else [self collapseItem:theItem];
            }
        }
    }
	blockExpandOrCollapseFromPropagatingBackUp = NO;
}


-(void) reloadData {
    [super reloadData];
    [self syncExpandedObjects:self.expandedObjects];
}

- (void)reloadItem:(id)theItem {
    [super reloadItem:theItem];
    [self syncExpandedObjectsToTreeNode:theItem syncChildren:NO];
}

- (void)reloadItem:(id)theItem reloadChildren:(BOOL)theReloadChildren {
    [super reloadItem:theItem reloadChildren:theReloadChildren];
    [self syncExpandedObjectsToTreeNode:theItem syncChildren:theReloadChildren];
}

-(void) dealloc {
	[expandedObjects release];
	[super dealloc];
}



@end
