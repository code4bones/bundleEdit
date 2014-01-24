//
//  SecondViewController.h
//  bundleEdit
//
//  Created by Pete on 11.02.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Toast.h"

@interface SecondViewController : UIViewController<UITableViewDataSource,
UITableViewDelegate,
UISearchDisplayDelegate>
{
    UITableView *tableView;
    UILabel *labelFound;
    __block NSMutableDictionary *_fileList;
    NSArray *_resList;
    NSMutableDictionary *_addList;
    NSLock *_lock;
    int _currentIndex;
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchCtrl;
}

@property(nonatomic,retain) IBOutlet UITableView *tableView;
@property(nonatomic,retain) IBOutlet UILabel *labelFound;
@property(nonatomic,retain) IBOutlet UISearchBar *_searchBar;
@property(nonatomic,retain) IBOutlet UISearchDisplayController *_searchCtrl;

-(id)initWithFiles:(NSDictionary*)addList;
-(IBAction)onLoad:(id)sender;
-(IBAction)onAdd:(id)sender;
-(IBAction)onMoveToCheckMark:(id)sender;
-(void)recursivePathsForResourcesOfType: (NSString *)type inDirectory: (NSString *)directoryPath;
-(void)updateTable:(id)obj;
- (void)filterContentForSearchText:(NSString*)searchText 
                             scope:(NSString*)scope;


@end
