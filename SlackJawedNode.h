//
//  SlackJawedNode.h
//  TreeArchive
//
//  Created by Kevin Doughty on 7/16/11.
//  Copyright 2011 Kevin Doughty. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//@class MyDocument;
@class SlackJawedContext;
@interface SlackJawedNode : NSObject {
	SlackJawedContext *context;
	SlackJawedNode *parent;
	NSMutableArray *children;
	NSString *name;
}
@property (assign) SlackJawedContext *context;
@property (assign) SlackJawedNode *parent;
@property (retain) NSMutableArray *children;
@property (copy) NSString *name;

-(void)insertObject:(id)theObject inChildrenAtIndex:(NSUInteger)theIndex;
-(void)removeObjectFromChildrenAtIndex:(NSUInteger)theIndex;
-(id)initWithCoder:(NSCoder *)coder;
-(void)encodeWithCoder:(NSCoder *)coder;

//-(SlackJawedNode*)debugDescendantNodeAtIndexPath:(NSIndexPath*)theIndexPath;

@end
