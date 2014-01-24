//
//  SecondViewController.m
//  bundleEdit
//
//  Created by Pete on 11.02.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "SecondViewController.h"
#import "FirstViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

@synthesize tableView,labelFound,_searchBar,_searchCtrl;

-(id)initWithFiles:(NSMutableDictionary*)addList {
    _lock = [[NSLock alloc]init];
    _addList = addList;
    
    NSString *cache = [FirstViewController applicationCacheFile];
    NSLog(@"Cache %@\n",cache);
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:cache];
    if ( dic != nil )
        _fileList = [NSMutableDictionary dictionaryWithDictionary:dic];
    else
        _fileList = [[NSMutableDictionary alloc]init ];
    _currentIndex = -1;
    self = [super initWithNibName:@"SecondViewController" bundle:nil ];
    if (self) {
        self.title = @"Scan";//NSLocalizedString(@"Second", @"Second");
        self.tabBarItem.image = [UIImage imageNamed:@"find"];
    }
    return  self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Second", @"Second");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}

-(IBAction)onLoad:(id)sender {
    [_fileList removeAllObjects];
    exec_progress(@"Wait", @"Scanning for plists", ^{
#if 0
        NSString *path = @"/Users/code4bones/Development/src/";
#else
        NSString *path = @"/";
#endif
        [self recursivePathsForResourcesOfType:@"plist" inDirectory:path];
    },^{
        [self.tableView reloadData];
        NSString *cache = [FirstViewController applicationCacheFile];
        [_fileList writeToFile:cache atomically:YES];
    }); // exec_progress
}

-(IBAction)onAdd:(id)sender {
    NSString *bmFullName = [FirstViewController applicationBookmarksFile];
    if([_addList writeToFile:bmFullName atomically:NO] == NO )
        toast(@"ERROR !",@"Cannot write to %@\n",bmFullName);
}

-(IBAction)onMoveToCheckMark:(id)sender {
    BOOL fNext = ((UITableViewCell*)sender).tag == 2;
    if ( _currentIndex == -1 ) 
        _currentIndex = 0;
    else {
        if ( fNext ) {
            _currentIndex++;
            _currentIndex %= _addList.count;
        } else {
            if ( _currentIndex > 0 )
                _currentIndex--;
            else {
                _currentIndex = _addList.count-1;
            }
        }
    }
    int row = 0;
    NSString *selectedKey = [[_addList allKeys]objectAtIndex:_currentIndex];
    for ( NSString *key in [_fileList allKeys] ) {
        if ( [selectedKey isEqualToString:key] )
            break;
        row++;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)tableView:(UITableView *)tableVw didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableVw cellForRowAtIndexPath:indexPath];
    
    NSArray *paths;
    if ( [tableVw isEqual:self.searchDisplayController.searchResultsTableView] )
        paths = _resList;
    else
        paths = [_fileList allKeys ];
    
    NSString *file = [paths objectAtIndex:indexPath.row];
    if ( cell.accessoryType == UITableViewCellAccessoryCheckmark ) {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [_addList removeObjectForKey:file];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [_addList setValue:[file lastPathComponent] forKey:file];
    }
    [self onAdd:self];
    labelFound.text = [NSString stringWithFormat:@"Found %d / %d",_fileList.count,_addList.count];
    
}


- (NSInteger)tableView:(UITableView *)tableVw numberOfRowsInSection:(NSInteger)section
{
    if ( [tableVw isEqual:self.searchDisplayController.searchResultsTableView] )
        return _resList.count;
    
    return _fileList.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableVw cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellID = @"FileCell"; 
    UITableViewCell *cell = [tableVw dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    NSArray *paths;
    [_lock lock];
    if ( [tableVw isEqual:self.searchDisplayController.searchResultsTableView] )
        paths = [NSArray arrayWithArray:_resList ];
    else
        paths = [_fileList allKeys];
    [_lock unlock];
    NSString *file = [paths objectAtIndex:indexPath.row];
    cell.textLabel.text = [file lastPathComponent];
    cell.detailTextLabel.text = file;
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.numberOfLines = 3;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    if ( [_addList objectForKey:file ] != nil ) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    //cell.
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 84;
}

- (void)filterContentForSearchText:(NSString*)searchText 
                             scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate 
                                    predicateWithFormat:@"SELF contains[cd] %@",
                                    searchText];
    
    _resList = [[_fileList allKeys] filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString 
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] 
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:searchOption]];
    
    return YES;
}

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    labelFound.text = [NSString stringWithFormat:@"Found %d / %d",_fileList.count,_addList.count];
        
    //[ tableView reloadData];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(void)updateTable:(id)obj {
    labelFound.text = [NSString stringWithFormat:@"Found %d / %d",_fileList.count,_addList.count];
    [tableView reloadData];
}

- (void) recursivePathsForResourcesOfType: (NSString *)type inDirectory: (NSString *)directoryPath{
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    NSString *filePath;
    while ( (filePath = [enumerator nextObject] ) != nil ){
        if( [[filePath pathExtension] isEqualToString:type] ){
            NSString *key = [directoryPath stringByAppendingString: filePath];
            [_lock lock];
            [_fileList setObject:[filePath lastPathComponent] forKey:key];
            [_lock unlock];
            [self performSelectorOnMainThread:@selector(updateTable:) withObject:nil waitUntilDone:YES];    
        }
    }
}

@end
