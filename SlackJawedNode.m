//
//  SlackJawedNode.m
//  TreeArchive
//
//  Created by Kevin Doughty on 7/16/11.
//  Copyright 2011 Kevin Doughty. All rights reserved.
//

#import "SlackJawedNode.h"
#import "SlackJawedContext.h"

@implementation SlackJawedNode
@synthesize name, parent, children, context;


-(id) init {
	if ((self = [super init])) {
		
	}
	return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
		self.children = [coder decodeObjectForKey:@"children"];
		self.parent = [coder decodeObjectForKey:@"parent"];
		self.name = [coder decodeObjectForKey:@"name"];
		self.context = [coder decodeObjectForKey:@"context"];
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:parent forKey:@"parent"];
	[coder encodeObject:children forKey:@"children"];
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:context forKey:@"context"];
}
-(NSMutableArray*)children {
	if (children == nil) children = [[NSMutableArray alloc] init];
	return children;
}
-(void) setChildren:(NSMutableArray*)theChildren {
    [children release];
    children = [theChildren retain];
}
-(void) dealloc {
	[name release];
	[children release];
	[super dealloc];
}



-(void)insertObject:(id)theObject inChildrenAtIndex:(NSUInteger)theIndex {
    SlackJawedNode *theNode = theObject;
    [[self.context.undoManager prepareWithInvocationTarget:self] removeObjectFromChildrenAtIndex:theIndex];
	if (![self.context.undoManager isUndoing]) {
        [self.context.undoManager setActionName:[NSString stringWithFormat:@"insertObjectIn:%@ atIndex:%ld",[self name],(unsigned long)theIndex]];
	} else {
        [self.context.undoManager setActionName:[NSString stringWithFormat:@"removeObjectIn:%@ atIndex:%ld",[self name],(unsigned long)theIndex]];
	}
    theNode.context = self.context;
	theNode.parent = self;
	[children insertObject:theNode atIndex:theIndex];
}

-(void)removeObjectFromChildrenAtIndex:(NSUInteger)theIndex {
	SlackJawedNode *theNode = [children objectAtIndex:theIndex];
    [[self.context.undoManager prepareWithInvocationTarget:self] insertObject:theNode inChildrenAtIndex:theIndex];
	if (![self.context.undoManager isUndoing]) {
        [self.context.undoManager setActionName:[NSString stringWithFormat:@"removeObjectIn:%@ atIndex:%ld",[self name],(unsigned long)theIndex]];
	} else {
        [self.context.undoManager setActionName:[NSString stringWithFormat:@"insertObjectIn:%@ atIndex:%ld",[self name],(unsigned long)theIndex]];
	}
	theNode.context = nil;
	theNode.parent = nil;
	[children removeObjectAtIndex:theIndex];
}
-(NSString*)name {
    return name;
}
-(void) setName:(NSString*)theName {
	[self.context.undoManager registerUndoWithTarget:self selector:@selector(setName:) object:[[name copy] autorelease]]; // avoids warning: multiple methods named '-setName:' found
	if (![self.context.undoManager isUndoing]) {
        [self.context.undoManager setActionName:[NSString stringWithFormat:@"setName:%@",theName]];
	} else {
        [self.context.undoManager setActionName:[NSString stringWithFormat:@"setName:%@",self.name]];
    }
	[name release];
	name = [theName copy];
}

@end
