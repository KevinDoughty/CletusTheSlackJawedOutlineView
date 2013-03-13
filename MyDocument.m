//
//  MyDocument.m
//  TreeArchive
//
//  Created by Kevin Doughty on 7/16/11.
//  Copyright Kevin Doughty 2011 . All rights reserved.
//

#import "MyDocument.h"
#import "SlackJawedContext.h"
#import "SlackJawedNode.h"

#define kNodesPasteBoardType @"draggedNodesPasteBoardType"

@implementation MyDocument
@synthesize slackJawedContext;

- (id)init {
    if ((self = [super init])) {
		slackJawedContext = [[SlackJawedContext alloc] init];
		slackJawedContext.name = @"ROOT NODE";
    }
    return self;
}

- (NSString *)windowNibName {
   return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
	[super windowControllerDidLoadNib:aController];
	slackJawedContext.undoManager = self.undoManager; // set for both new and loaded documents
	[outlineView registerForDraggedTypes:[NSArray arrayWithObject:kNodesPasteBoardType]];
	[outlineView bind:@"expandedObjects" toObject:slackJawedContext withKeyPath:@"expandedObjects" options:nil];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	NSData *theData = [NSKeyedArchiver archivedDataWithRootObject:slackJawedContext];
	if (theData != nil) return theData;
	
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	self.slackJawedContext = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}






-(void) dealloc {
	
	[slackJawedContext release];
	[super dealloc];
}


#pragma mark - NSOutlineView drag and drop




-(BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteBoard {
	[pasteBoard declareTypes:[NSArray arrayWithObject:kNodesPasteBoardType] owner:self];
	[pasteBoard setData:[NSKeyedArchiver archivedDataWithRootObject:[items valueForKey:@"indexPath"]] forType:kNodesPasteBoardType];
	return YES;
}


- (BOOL) category:(id)cat isSubCategoryOf:(id) possibleSub {
	while (possibleSub != NULL) {		
		if (possibleSub == cat) return YES;
		possibleSub = [possibleSub valueForKey:@"parent"]; // hardcoded inverse relationship hard coded
	}	
	return NO;
}


- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)targetTreeNode proposedChildIndex:(NSInteger)index {
	NSPasteboard *pboard = [info draggingPasteboard];
	if (![pboard availableTypeFromArray:[NSArray arrayWithObject:kNodesPasteBoardType]]) return NSDragOperationNone;
	NSArray *draggedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:kNodesPasteBoardType]];
	for (NSIndexPath *draggedIndexPath in draggedIndexPaths) {
		SlackJawedNode *theDraggedNode = [[[treeController arrangedObjects] descendantNodeAtIndexPath:draggedIndexPath] representedObject];
		if ([self category:theDraggedNode isSubCategoryOf:[targetTreeNode representedObject]]) return NSDragOperationNone;
	}
	return NSDragOperationMove;
}


-(BOOL)outlineView:(NSOutlineView*)theOutlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)targetTreeNode childIndex:(NSInteger)theDestinationIndex { // "targetItem" is a NSTreeNode proxy
	BOOL verbose = NO;
    
	SlackJawedNode *targetNode = [targetTreeNode representedObject];
    NSIndexPath *targetIndexPath = [targetTreeNode indexPath];
	if (targetTreeNode == nil) { // top level tree node is nil, not [treeController arrangedObjects]
        targetNode = self.slackJawedContext;
        targetIndexPath = [[NSIndexPath alloc] init];
    }
    
	if (theDestinationIndex < 0) theDestinationIndex = [[targetNode valueForKey:[treeController childrenKeyPath]] count]; // NOT remove? // index is -1 if you drop on a folder // valueForKey because it's simple.
	
	NSMutableArray *draggedTreeNodes = [NSMutableArray array];
	NSArray *draggedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:kNodesPasteBoardType]];
	id arrangedObjects = [treeController arrangedObjects];
	for (NSIndexPath *draggedIndexPath in draggedIndexPaths) {
		[draggedTreeNodes addObject:[arrangedObjects descendantNodeAtIndexPath:draggedIndexPath]];
	}
	if (verbose) NSLog(@"::::: outlineView:acceptDrop:item:childIndex");
	BOOL moveNodesViaTreeController = NO;
	if (moveNodesViaTreeController) {
        NSLog(@"using NSTreeController moveNodes:toIndexPath: will not work because changes are not propagated to the model.");
		NSIndexPath *destinationIndexPath = [[targetTreeNode indexPath] indexPathByAddingIndex:theDestinationIndex];
        [treeController moveNodes:draggedTreeNodes toIndexPath:destinationIndexPath];
        
        NSMutableArray *indexPathList = [NSMutableArray array];
        NSInteger i = [draggedTreeNodes count];
        for (i = 0; i < [draggedTreeNodes count]; i++) {
            NSIndexPath *theIndexPath = [[targetTreeNode indexPath] indexPathByAddingIndex:theDestinationIndex++];
            [indexPathList addObject:theIndexPath];
        }
        [treeController setSelectionIndexPaths: indexPathList];
		
	} else {
		// moveNodes does not propagate relationship changes to the model
        // NSTreeController isn't configured to handle an inverse relationship, it manages that itself.
        
        // old way loses selection when dragging from the top level to the top level
        // old way does not expand items when adding children
        
        // new way selection is ok when dragging from the top level to the top level
        // new way only expands items when adding children to a node above it.
        // if adding a node as a child of one that appears below it,
        // it tries to expand the wrong item.
        // If you drag 3 to 4, 5 is expanded.
        
        
        BOOL removeThenReinsertExpandedObjects = NO; // doesn't work.
        
        NSInteger shift = 0; // shift is applied to destination index and always negative, for moved & target nodes with the same parent.
        
        
        if (verbose) NSLog(@": targetTreeNode %@",targetTreeNode);
        if (verbose) NSLog(@": indexPath %@",targetIndexPath);
        if (verbose) NSLog(@": destinationIndex %ld;",theDestinationIndex);
        [draggedTreeNodes sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:YES]]];
        NSInteger i = [draggedTreeNodes count];
        
        NSMutableSet *reExpandedObjects = [NSMutableSet set];
        
        while (i--) { // calculate new targetIndexPath for after nodes are removed. Do not remove treeNodes yet, because adding or removing top level nodes results in a call to NSTreeController setContent: which might wipe out the existing tree nodes.
            NSTreeNode *theTreeNode = [[draggedTreeNodes objectAtIndex:i] retain];
            NSIndexPath *theIndexPath = [theTreeNode indexPath];
            NSUInteger j = 0;
            SlackJawedNode *theNode = [theTreeNode representedObject];
            if (removeThenReinsertExpandedObjects && [slackJawedContext.expandedObjects containsObject:theNode]) {
                [reExpandedObjects addObject:theNode];
                [[slackJawedContext mutableSetValueForKey:@"expandedObjects"] removeObject:theNode];
            }
            NSUInteger theLength = [theIndexPath length];
            NSUInteger theTargetLength = [targetIndexPath length];
            NSUInteger theOldIndex = [theIndexPath indexAtPosition:[theIndexPath length]-1];
            NSTreeNode *theParentTreeNode = [theTreeNode parentNode];
            if (theParentTreeNode == nil && targetTreeNode == nil) {
                if (verbose) NSLog(@": nil parent and target nodes");
            }
            if (theParentTreeNode == targetTreeNode || (targetTreeNode == nil && [theParentTreeNode parentNode] == nil)) { // Ridiculous. arrangedObjects returns a proxy tree node. Passed targetNode argument is nil for top level. Asking for a treeNode's parentNode that is the top level returns an actual treeNode, not nil or the arrangedObjects proxy. The representedObject of this top level treeNode is a dictionary populated with the children key path, not the object the treeController is bound to.
                if (theOldIndex < theDestinationIndex) {
                    shift--; 
                    if (verbose) NSLog(@": shift:%ld;",shift);
                }
            }
            
            if (theLength <= theTargetLength) {
                for (j=0; j < theLength-1; j++) {
                    if ([theIndexPath indexAtPosition:j] != [targetIndexPath indexAtPosition:j]) {
                        j = NSNotFound-1;
                    }
                }
                if (j != NSNotFound && [theIndexPath indexAtPosition:j] < [targetIndexPath indexAtPosition:j]) {
                    NSUInteger *theIndexes = (NSUInteger*)malloc(sizeof(NSUInteger) * theTargetLength);
                    for (NSUInteger k = 0; k<j; k++) {
                        theIndexes[k] = [targetIndexPath indexAtPosition:k];
                    }
                    theIndexes[j] = [targetIndexPath indexAtPosition:j] - 1;
                    for (NSUInteger k = j+1; k < theTargetLength; k++) {
                        theIndexes[k] = [targetIndexPath indexAtPosition:k];
                    }
                    targetIndexPath = [[[NSIndexPath alloc] initWithIndexes:theIndexes length:theTargetLength] autorelease];
                    free(theIndexes);
                    if (verbose) NSLog(@": ADJUSTED indexPath %@",targetIndexPath);
                }
            }
        }  
        
        i = [draggedTreeNodes count];
        NSArray *draggedModelNodes = [draggedTreeNodes valueForKey:@"representedObject"];
        while (i--) {
            SlackJawedNode *theNode = [[draggedModelNodes objectAtIndex:i] retain];
            SlackJawedNode *theParentNode = theNode.parent; // inverse relationship hard coded!
            NSMutableArray *theOldMutableArray = [theParentNode mutableArrayValueForKey:[treeController childrenKeyPath]];
            NSUInteger theOldIndex = [theOldMutableArray indexOfObject:theNode];
            if (theOldIndex != NSNotFound) { // shouldn't be NSNotFound
                if (verbose) NSLog(@": remove %@",theNode);
                [theOldMutableArray removeObjectAtIndex:theOldIndex]; // causes NSTreeController setContent: if it's from or to the top level:
            }
            if ([theOldMutableArray count] == 0) {
                [[slackJawedContext mutableSetValueForKey:@"expandedObjects"] removeObject:theParentNode];
            }
            [theNode release];
        }
        
        
        
        
        NSMutableArray *theNewMutableArray = [targetNode mutableArrayValueForKey:[treeController childrenKeyPath]];
        NSMutableIndexSet *destinationIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(theDestinationIndex + shift, [draggedModelNodes count])];
        if (verbose) NSLog(@": insert %@",draggedModelNodes);
        if (verbose) NSLog(@": destination indexes %@",destinationIndexes);
        if (verbose) NSLog(@": preMutableArray %@",theNewMutableArray);
        [theNewMutableArray insertObjects:draggedModelNodes atIndexes:destinationIndexes];
        if (verbose) NSLog(@": postMutableArray %@",theNewMutableArray);
        NSMutableArray *indexPathList = [NSMutableArray array];
        
        if (targetNode != nil && targetNode != slackJawedContext) {
            if (verbose) NSLog(@": add target node to expandedObjects");
            [[slackJawedContext mutableSetValueForKey:@"expandedObjects"] addObject:targetNode];
        }
        if (removeThenReinsertExpandedObjects) [[slackJawedContext mutableSetValueForKey:@"expandedObjects"] unionSet:reExpandedObjects];
        
        if (verbose) NSLog(@": targetTreeNode %@",targetTreeNode);
        if (verbose) NSLog(@": representedObject %@",[targetTreeNode representedObject]);
        if (verbose) NSLog(@": targetTreeNode indexPath %@",[targetTreeNode indexPath]);
        if (verbose) NSLog(@": targetIndexPath %@",targetIndexPath);
        
        for (i = 0; i < [draggedTreeNodes count]; i++) {
            NSIndexPath *theIndexPath = [targetIndexPath indexPathByAddingIndex:theDestinationIndex + i + shift];
            [indexPathList addObject:theIndexPath];
        }
        if (verbose) NSLog(@": indexPathList %@",indexPathList);
        [treeController setSelectionIndexPaths: indexPathList];
        
        NSLog(@"new expanded objects:%@;", slackJawedContext.expandedObjects);
        
        
	}
	if (verbose) NSLog(@"::::: END outlineView:acceptDrop:item:childIndex");
	return YES;
}


@end
