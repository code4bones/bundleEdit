//
//  FirstViewController.m
//  bundleEdit
//
//  Created by Pete on 11.02.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "FirstViewController.h"
#import "DictionaryListController.h"
#import "NetLog/NetLog.h"
#import "Toast.h"

@interface FirstViewController () 
{
    NSMutableDictionary *m_dict;
}
@end

@implementation FirstViewController

@synthesize btnShow,fileView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Favorites";
        self.tabBarItem.image = [UIImage imageNamed:@"star"];
        NSString *docPath = [FirstViewController applicationDocumentsDirectory];
        docPath = [docPath stringByAppendingPathComponent:@"bundleEdit.log.txt"];
        [NetLog setup:docPath];
        netlog(@"Started\n");
    }
    return self;
}
			
-(void)loadBookmarks {
    NSString *bmFullName = [FirstViewController applicationBookmarksFile];
    netlog(@"Bookmarks loaded from %@\n",bmFullName);
    _fileList = [NSMutableDictionary dictionaryWithContentsOfFile:bmFullName];
    [self.fileView reloadData];
 }

-(void) saveFile {
    NSString *fileName = [[FirstViewController applicationWorkspaceDirectory] stringByAppendingPathComponent:[currentFile lastPathComponent]];
    netlog(@"Saving %@\n",fileName);
    if( [m_dict writeToFile:fileName atomically:NO] == NO )
        toast(@"ERROR!",@"Cannot save %@",currentFile);
    else {
        toast(@"Saved!",@"%@",currentFile);
    }
    [self copyFile:fileName];
}

-(void)copyFile:(NSString*)source {
    NSString *cmd = [NSString stringWithFormat:
     @"ssh root@localhost cp -fv \"%@\" \"%@\"",source,currentFile];
    const char *pCmd = [cmd cStringUsingEncoding:NSUTF8StringEncoding];                  
    netlog(@"%s\n",pCmd);
    FILE *fd = popen(pCmd,"r");
    NSMutableString *msg = [[NSMutableString alloc]init];
    if ( fd ) {
        while ( !feof(fd) ) {
            char buf[4096];
            char *p = fgets(buf,sizeof(buf),fd);
            if ( p == 0 )
                break;
            [msg appendFormat:@"%s",p]; 
        }
        netlog(@">>\n%@\n<<\n",msg);
        int ret = pclose(fd);
        //if ( ret != 0 )
        netlog(@"pclose() => %d\n",ret);
    } else {
        alert(@"popen",@"%s",strerror(errno));
    }
}

-(void)loadFile
{
    m_dict = [NSMutableDictionary dictionaryWithContentsOfFile:currentFile];
    if ( m_dict == nil )
        alert(@"error",@"Cannot open %@\n",currentFile);
    else {
        DictionaryListController *ctrl = [[DictionaryListController alloc] initWithDictionary:m_dict];
        ctrl._firstViewController = self;
        ctrl.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:ctrl animated:YES];
    }
}



+ (NSString *) applicationDocumentsDirectory 
{    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    basePath = [basePath stringByAppendingPathComponent:@"bundleEdit"];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = YES;
    if ( [ fm fileExistsAtPath:basePath isDirectory:&isDir] == NO ) {
        NSError *error = nil;
        if ( [fm createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error] == NO )
            alert(@"IO ERROR",@"%@\n(%@)",[error localizedDescription],basePath);
    }
    return basePath;
}

+ (NSString *) applicationWorkspaceDirectory 
{
    NSString *basePath = [FirstViewController applicationDocumentsDirectory];
    basePath = [basePath stringByAppendingPathComponent:@"workspace"];
    BOOL isDir = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ( [ fm fileExistsAtPath:basePath isDirectory:&isDir] == NO ) {
        NSError *error = nil;
        if ( [fm createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error] == NO )
            alert(@"IO ERROR",@"%@\n(%@)",[error localizedDescription],basePath);
    }
    return basePath;
}

+ (NSString *) applicationBookmarksFile
{
    return [ [FirstViewController applicationDocumentsDirectory] stringByAppendingPathComponent:@"bookmarks.plist"];
}

+ (NSString *) applicationCacheFile
{
    return [[FirstViewController applicationDocumentsDirectory] stringByAppendingPathComponent:@"cache.plist"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL fDir = YES;
    NSString *docPath = [FirstViewController applicationWorkspaceDirectory];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ( [fm fileExistsAtPath:docPath isDirectory:&fDir] ) {
        NSLog(@"documents exists %@\n",docPath);
    } else {
        NSError *error = nil;
        if ( [fm createDirectoryAtPath:docPath withIntermediateDirectories:YES attributes:nil error:&error] == NO )
            alert(@"Error!",@"cannot create %@\n%@",docPath,[error localizedDescription]);
        else {
            toast(@"Message",@"Intermidiate directory at %@",docPath);
        }
    }
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _fileList.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableVie cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellID = @"FileCell"; 
    UITableViewCell *cell = [tableVie dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    NSArray *keys = [_fileList allKeys];
    NSString *file = [keys objectAtIndex:indexPath.row];
    cell.textLabel.text = [file lastPathComponent];
    cell.detailTextLabel.text = [file stringByDeletingLastPathComponent];
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.numberOfLines = 3;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    //UILineBreakModeMiddleTruncation;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 84;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentFile = [[_fileList allKeys] objectAtIndex:indexPath.row];
    [self loadFile];
}


-(void) viewDidAppear:(BOOL)animated {
    [self loadBookmarks];
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

@end
