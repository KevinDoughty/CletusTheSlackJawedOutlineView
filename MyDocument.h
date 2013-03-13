//
//  MyDocument.h
//  TreeArchive
//
//  Created by Kevin Doughty on 7/16/11.
//  Copyright Kevin Doughty 2011 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
@class SlackJawedContext;
@class SlackJawedOutlineView;
@interface MyDocument : NSDocument {
	IBOutlet NSTreeController *treeController;
	IBOutlet SlackJawedOutlineView *outlineView;
	SlackJawedContext *slackJawedContext;
	
}

@property (retain) SlackJawedContext *slackJawedContext;

@end
