//
//  FirstViewController.h
//  bundleEdit
//
//  Created by Pete on 11.02.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DictionaryListController.h"

@interface FirstViewController : UIViewController<
UITableViewDataSource,
UITableViewDelegate,
DataSinkProtocol>
{
    NSMutableDictionary *_fileList;
    UITableView *fileView;
    NSString *currentFile;
}

@property(strong,nonatomic) IBOutlet UIButton *btnShow;
@property(strong,nonatomic) IBOutlet UITableView *fileView;

-(void)loadBookmarks;
-(void)copyFile:(NSString*)file;
-(void)loadFile;
+ (NSString *) applicationDocumentsDirectory;
+ (NSString *) applicationWorkspaceDirectory;
+ (NSString *) applicationBookmarksFile;
+ (NSString *) applicationCacheFile;

@end
