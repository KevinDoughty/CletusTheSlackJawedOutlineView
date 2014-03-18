//
//  SlackJawedContext.m
//  TreeArchive
//
//  Created by Kevin Doughty on 7/26/11.
//  Copyright 2011 Kevin Doughty. All rights reserved.
//

#import "SlackJawedContext.h"
#import "SlackJawedOutlineView.h"

@implementation SlackJawedContext
@synthesize undoManager;
@synthesize expandedObjects, selectionIndexPaths;


+(NSArray*)preservedKeys {
    return @[@"expandedObjects",@"selectionIndexPaths"];
}
- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
        for (NSString *theKey in [SlackJawedContext preservedKeys]) {
            [self setValue:[coder decodeObjectForKey:theKey] forKey:theKey];
        }
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
    for (NSString *theKey in [SlackJawedContext preservedKeys]) {
        [coder encodeObject:[self valueForKey:theKey] forKey:theKey];
    }
}
-(SlackJawedContext*)context {
	return self;
}
-(void) setName:(NSString*)theName { // do not register undo for name
	name = [theName copy];
}
-(void) setParent:(SlackJawedContext*)nomnomnom {
	
}
-(SlackJawedContext*)parent {
	return nil;
}
-(NSIndexPath*)indexPath {
	return nil;
}

-(void) dealloc {
	self.undoManager = nil;
}







#pragma mark accessors


-(NSArray*)selectionIndexPaths {
	if (selectionIndexPaths == nil) selectionIndexPaths = [[NSArray alloc] init];
	return selectionIndexPaths;
}
-(void) setSelectionIndexPaths:(NSArray*)theSelectionIndexPaths {
	selectionIndexPaths = theSelectionIndexPaths;
}
-(NSSet*)expandedObjects {
	if (expandedObjects == nil) expandedObjects = [[NSMutableSet alloc] init];
	return expandedObjects;
}
-(void) setExpandedObjects:(NSSet*)theExpandedObjects {
	expandedObjects = [[NSMutableSet alloc] initWithSet:theExpandedObjects];
}
-(void) addExpandedObjectsObject:(id)theObject {
    if (expandedObjects == nil) expandedObjects = [[NSMutableSet alloc] init];
	[expandedObjects addObject:theObject];
}
-(void) removeExpandedObjectsObject:(id)theObject {
    [expandedObjects removeObject:theObject];
}




-(NSUndoManager*)undoManager {
    return undoManager;
}
-(void) setUndoManager:(NSUndoManager*)theUndoManager {
	if (undoManager != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
	if (theUndoManager != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelDidOpenGroup:) name:NSUndoManagerDidOpenUndoGroupNotification object:theUndoManager];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelWillCloseGroup:) name:NSUndoManagerWillCloseUndoGroupNotification object:theUndoManager];
	}
	undoManager = theUndoManager;
	
}


#pragma mark undo redo


-(void) registerAfter:(NSString*)theKey withObject:(id)theObject {
    if ([self.undoManager isRedoing]) {
        [self setValue:theObject forKey:theKey];
    }
    [[self.undoManager prepareWithInvocationTarget:self] registerAfter:theKey withObject:theObject];
}
-(void) registerBefore:(NSString*)theKey withObject:(id)theObject  {
    if ([self.undoManager isUndoing]) {
        [self setValue:theObject forKey:theKey];
    }
    [[self.undoManager prepareWithInvocationTarget:self] registerBefore:theKey withObject:theObject];
}
-(void) registerAfter:(NSString*)theKey {
    [self registerAfter:theKey withObject:[[self valueForKey:theKey] copy]];
}
-(void) registerBefore:(NSString*)theKey {
    [self registerBefore:theKey withObject:[[self valueForKey:theKey] copy]];
}


#pragma mark notification




-(void)modelDidOpenGroup:(id)theNotification {
   if ([self.undoManager groupingLevel] == 1) {
		for (NSString *theKey in [SlackJawedContext preservedKeys]) {
           [self registerBefore:theKey];
       }
    }
}
-(void)modelWillCloseGroup:(id)theNotification {
    if ([self.undoManager groupingLevel] == 1) {
        for (NSString *theKey in [SlackJawedContext preservedKeys]) {
            [self registerAfter:theKey];
        }
    }
}



@end
