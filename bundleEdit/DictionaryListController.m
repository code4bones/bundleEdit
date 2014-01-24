//
//  DictionaryListController.m
//  bundleEdit
//
//  Created by Pete on 12.02.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DictionaryListController.h"
#import "Toast.h"
#import "NetLog/NetLog.h"

@interface DictionaryListController () 
{
}
    
@end

@implementation DictionaryListController

@synthesize _tableView,_valueCell,_firstViewController,_toolBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id) initWithDictionary:(NSMutableDictionary*)otherDictionary
{
    self = [super initWithNibName:@"DictionaryListController" bundle:nil];
    if ( self == nil )
        return nil;
    
    _dict = otherDictionary;
    _searchMode = NO;
    _typeArray = [NSArray arrayWithObjects:
                  [[NSMutableArray alloc]init],
                  [[NSMutableDictionary alloc ] init],
                  [[NSMutableString alloc ]init ],
                  [NSNumber numberWithBool:YES], // boolean
                  [NSNumber numberWithInteger:1], // integer
                  [[NSDate alloc]init ],
                  nil];

    //for ( id o in _typeArray )
      //  NSLog(@"%@ (%@)\n",NSStringFromClass([o class]),o);
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
    
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{ // Default is 1 if not implemente
    
    BOOL fSearch = [tableView isEqual:self.searchDisplayController.searchResultsTableView];
    
    if ( [self isArray:fSearch] == YES )
        return [self asArray:fSearch].count; //((NSMutableDictionary*)_dict).count;

    //if ( [_dict isKindOfClass:[NSMutableArray class]] )
      //  return ((NSMutableArray*)_dict).count;
    
    return [self asDictionary:fSearch].count;
}

- (NSInteger)tableView:(UITableView *)tableVw numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellID = @"valueCell"; 
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        
        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        [[NSBundle mainBundle] loadNibNamed:@"ValueCell" owner:self options:nil];
        cell = _valueCell;
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        self._valueCell = nil;            
    
    }
    
    // setup controls
    UITextField *edKey = (UITextField*)[cell viewWithTag:scEditKey];
    UITextField *edValue = (UITextField*)[cell viewWithTag:scEditValue];
    UIButton *bnType = (UIButton*)[cell viewWithTag:scButtonType];
    UIButton *bnEdit = (UIButton*)[cell viewWithTag:scButtonEdit];
     
    
    [edKey addTarget:self action:@selector(onBeginEdit:)forControlEvents:UIControlEventEditingDidBegin];
    [edValue addTarget:self action:@selector(onBeginEdit:)forControlEvents:UIControlEventEditingDidBegin];
    
    [bnType addTarget:self action:@selector(onSelectType:)forControlEvents:UIControlEventTouchDown];
    [bnEdit addTarget:self action:@selector(onEditValue:) forControlEvents:UIControlEventTouchDown];
    
    NSString *keyVal;
    NSString *keyName;
    
    BOOL fSearch = tableView == self.searchDisplayController.searchResultsTableView;
    
    keyName = [self getKeyStringAt:indexPath.section forMode:fSearch];//[[_dict allKeys] objectAtIndex:indexPath.section];
    id valObj = [self getValueObjectAt:indexPath.section forMode:fSearch];//[[_dict allValues] objectAtIndex:indexPath.section];
    
    if ( [valObj isKindOfClass:[NSMutableArray class]] || 
         [valObj isKindOfClass:[NSMutableDictionary class]] ) {
        keyVal = NSStringFromClass([valObj class]);
        [bnEdit setHidden:NO];
        [edValue setEnabled:NO];
        [edValue setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        //[bnEdit setHidden:NO];
        [edValue setEnabled:YES];
        [edValue setBackgroundColor:[UIColor whiteColor]];

        if ( [valObj isKindOfClass:[NSDate class]] ) {
            keyVal = [_dateFormatter stringFromDate:valObj];
            edValue.placeholder = @"DD.MM.YYYY HH:MM:SS";
        }
        else {
            keyVal = [NSString stringWithFormat:@"%@",valObj];
            edValue.placeholder = @"Value...";
        }
        [bnEdit setHidden:YES];
    }
        
    [edKey setEnabled:[self isArray:fSearch ] == NO];
    
    if ( [self isArray:fSearch] == YES ) {
        [edKey setBackgroundColor:[UIColor lightGrayColor]];    
    }
    edKey.text = keyName;
    edValue.text = keyVal;;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle != UITableViewCellEditingStyleDelete )
        return;
    if ( [self isArray:_searchMode] ) {
        NSMutableArray *arr = [self asArray:_searchMode];//(NSMutableArray*)_dict;
        [arr removeObjectAtIndex:indexPath.section];
    } else {
        NSMutableDictionary *dic = [self asDictionary:_searchMode];//(NSMutableDictionary*)_dict;
        [dic removeObjectForKey:[[dic allKeys] objectAtIndex:indexPath.section]];
    }
    [_tableView reloadData];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == actionSheet.cancelButtonIndex )
        return;
    if ( buttonIndex == actionSheet.destructiveButtonIndex )
        return;
    
    NSString *selectedType = [actionSheet buttonTitleAtIndex:buttonIndex];
    int idx = [_typeArray indexOfObjectPassingTest:^(id obj,NSUInteger idx,BOOL *stop ) {
        NSString *type = NSStringFromClass([obj class]);
        if ( [type isEqualToString:selectedType] )
            return YES;
        return NO;
    }];
    id obj = [_typeArray objectAtIndex:idx];
    
    NSString *key = [self getKeyStringAt:_currentIndexPath.section forMode:_searchMode];

    if ( [self isArray:_searchMode] ) {
        NSMutableArray *arr = [self asArray:_searchMode]; //(NSMutableArray*)_dict;
        [arr replaceObjectAtIndex:_currentIndexPath.section withObject:obj];
    } else {
        NSMutableDictionary *dict = [self asDictionary:_searchMode];//(NSMutableDictionary*)_dict;
        [dict setValue:obj forKey:key];
    }
    [_tableView reloadData];
}

-(IBAction)onEditClicked:(id)sender
{
    [_tableView setEditing:[_tableView isEditing] == NO animated:YES];
}

-(IBAction)onAddClicked:(id)sender
{
    NSString *key;
    int index = 0;
    if ( [self isArray:_searchMode] ) {
        NSMutableArray *arr = [self asArray:_searchMode]; //(NSMutableArray*)_dict;
        key = [NSString stringWithFormat:@"Item %d",arr.count];
        [arr addObject:key];
        index = [arr indexOfObject:key];
    } else {
        NSMutableDictionary *dict = [self asDictionary:_searchMode];//(NSMutableDictionary*)_dict;
        key = [NSString stringWithFormat:@"Item %d",dict.count];
        [dict setValue:[NSMutableString stringWithString:@""] forKey:key];
        index = [[dict allKeys] indexOfObject:key];
    }
    [_tableView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    [_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}


-(IBAction)onBeginEdit:(id)sender 
{
    UITableViewCell *cell = [self cellFromSubControl:sender];
    _currentIndexPath = [self._tableView indexPathForCell:cell];
    [cell setSelected:YES];
}

-(IBAction)onSelectType:(id)sender
{
    UITableViewCell *cell = [self cellFromSubControl:sender];
    _currentIndexPath = [self._tableView indexPathForCell:cell];
    UITextField *edKey = [self subCtrlFromCell:cell subCtrl:scEditKey];
    NSString *sTitle = [NSString stringWithFormat:@"\"%@\"'s TYPE",edKey.text];
    id objVal = [self getValueObjectAt:_currentIndexPath.section forMode:_searchMode];
    NSString *thisType = NSStringFromClass([objVal class]);
    
    UIActionSheet *sheet = 
        [[UIActionSheet alloc] initWithTitle:sTitle 
            delegate:self 
            cancelButtonTitle:@"Cancel" 
            destructiveButtonTitle:thisType 
            otherButtonTitles:nil];
    
    for ( id obj in _typeArray ) {
        NSString *type = NSStringFromClass([obj class]);
        if ( [thisType isEqualToString:type] == NO )
            [sheet addButtonWithTitle:type];
    }
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showInView:self.view];
}

-(IBAction)onEditValue:(id)sender
{
    UITableViewCell *cell = [self cellFromSubControl:sender];
    _currentIndexPath = [self._tableView indexPathForCell:cell];
    id valObj = [self getValueObjectAt:_currentIndexPath.section forMode:_searchMode];//[[_dict allValues] objectAtIndex:_currentIndexPath.section];
    if ( [valObj isKindOfClass:[NSMutableArray class]] || 
        [valObj isKindOfClass:[NSMutableDictionary class]] ) {
        DictionaryListController *ctrl = [[DictionaryListController alloc] initWithDictionary:valObj];
        ctrl.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        //UIModalTransitionStyleCrossDissolve;
        
        [self presentModalViewController:ctrl animated:YES];
        
    } else {
        NSAssert(NO,@"PANIC !");
    }
}

-(IBAction)onDone:(id)sender 
{
    [self._firstViewController saveFile];
    [self dismissModalViewControllerAnimated:YES];
}


-(void)updateValues:(id)sender {
    UITextField *edit = (UITextField*)sender;
    NSString *key = [self getKeyStringAt:_currentIndexPath.section forMode:_searchMode];
    NSString *val = edit.text;
    id obj = nil;
    id oldObj = [self getValueObjectAt:_currentIndexPath.section forMode:_searchMode];

    NSString *nativeType = NSStringFromClass([oldObj class]);
    
    int typeIdx = [_typeArray indexOfObjectPassingTest:^(id obj,NSUInteger idx,BOOL *stop) {
        if ( [nativeType isEqualToString:NSStringFromClass([obj class])] )
            return YES;
        return NO;
    }];
    
    if ( edit.tag == scEditValue ) {
        if ( typeIdx == typeDate )
        {
            obj = [_dateFormatter dateFromString: val];   
            if ( obj == nil ) {
                alert(@"Format mismatch",@"Try: DD.MM.YYYY HH:MM:SS");
                return;
            }
        } else if ( typeIdx == typeString ) {
            obj = [NSString stringWithString:val];
        } else if ( typeIdx == typeInteger ) {
            obj = [NSNumber numberWithInt:[val integerValue]];
        } else if ( typeIdx == typeBoolean ) {
            obj = [NSNumber numberWithBool:[val isEqualToString:@"1"]];
        }
    } else {
        // Editing a key name
        obj = edit.text;
    }
    
    if ( obj != nil ) {
        if ( [self isArray:_searchMode ] ) {
            NSMutableArray *arr = [self asArray:_searchMode]; //(NSMutableArray*)_dict;
            [arr replaceObjectAtIndex:_currentIndexPath.section withObject:obj];
        } else {
            NSMutableDictionary *dic = [self asDictionary:_searchMode]; //(NSMutableDictionary*)_dict;
            if ( edit.tag == scEditValue ) // value
                [dic setValue:obj forKey:key];
            else { // replace a key name
                [dic removeObjectForKey:key];
                [dic setValue:oldObj forKey:obj];
            }
        }
    } else
        toast(@"Warning",@"Not assinged");
    [self._tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)onEditingDone:(id)sender
{
    [self updateValues:sender];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {          // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
    if ( textField.tag == scEditKey ) {
        NSString *key = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \r\n\r"]];
        if ( key == nil || key.length == 0 ) {
            toast(@"Error",@"KEY CANNOT BE EMPTY");
            return NO;
        }
#if 0
        if ( [_dict isKindOfClass:[NSMutableDictionary class]] ) {
            //NSMutableDictionary *dict = (NSMutableDictionary*)_dict;
            NSArray *arr = [_dict allKeys];
            //NSMutableSet *set = [arr mutableSetValueForKey:key];
            NSUInteger idx = [arr indexOfObject:key];
            if ( idx != NSNotFound && idx != _currentIndexPath.section ) {
                NSString *other = [arr objectAtIndex:idx];
                NSLog(@"Found %@ at %d ( cur %@ )\n",other,idx,key);
                toast(@"Error",@"Duplicate key name");
                return NO;
            }
        }
#endif
        //[self updateValues:textField];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {              // called when 'return' key pressed. return NO to ignore.
    
    //[self updateValue:textField];
    [textField resignFirstResponder];
    
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 89;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)filterContentForSearchText:(NSString*)searchText 
                             scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate 
                                    predicateWithFormat:@"SELF contains[cd] %@",
                                    searchText];
    NSArray *keys;
    
    if ( [_dict isKindOfClass:[NSMutableDictionary class]] ) {
        keys = [[_dict allKeys] filteredArrayUsingPredicate:resultPredicate];
        NSArray *vals = [_dict objectsForKeys:keys notFoundMarker:@"Not Found"];
        _resList = [NSMutableDictionary dictionaryWithObjects:vals forKeys:keys];
    } else {
        keys = [_dict filteredArrayUsingPredicate:resultPredicate];
        _resList = [NSMutableArray arrayWithArray:keys];
    }
     
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


- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    _searchMode = YES;
    [_toolBar setUserInteractionEnabled:_searchMode == NO];
    
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    _searchMode = NO;
    [_toolBar setUserInteractionEnabled:_searchMode == NO];
}


#pragma - Utils



-(NSMutableDictionary*)asDictionary:(BOOL)isSearch
{
    return (NSMutableDictionary*)(isSearch?_resList:_dict);
}

-(NSMutableArray*)asArray:(BOOL)isSearch
{
    return (NSMutableArray*)(isSearch?_resList:_dict);
}

-(NSString*)getKeyStringAt:(NSInteger)index forMode:(BOOL)isSearch {
    if ( [self isArray:isSearch ] == NO) {
        NSDictionary *dict = (NSDictionary*)(isSearch?_resList:_dict);
        NSArray *allKeys = [dict allKeys];
        return [allKeys objectAtIndex:index];
    } 
    NSString *key = [NSString stringWithFormat:@"Item %d",index];
    return key;
}

-(id)getValueObjectAt:(NSInteger)index forMode:(BOOL)isSearch {
    if ( [self isArray:isSearch ] == NO) {
        NSDictionary *dict = (NSDictionary*)(isSearch?_resList:_dict);
        NSArray *allObj = [dict allValues];
        return [allObj objectAtIndex:index];
    } 
    NSArray *arr = (NSArray*)(isSearch?_resList:_dict);
    return [arr objectAtIndex:index];
}

-(BOOL)isArray:(BOOL)isSearch {
    if ( isSearch == YES )
        return [_resList isKindOfClass:[NSMutableArray class]]; 
    return [_dict isKindOfClass:[NSMutableArray class]];
}

-(UITableViewCell*) cellFromSubControl:(id)sub {
    if ( sub == nil )
        return nil;
    if ([sub isKindOfClass:[UITableViewCell class]] )
        return (UITableViewCell*)sub;
    return [self cellFromSubControl:((UIView*)sub).superview];
}

-(id)subCtrlFromCell:(UITableViewCell*)cell subCtrl:(NSInteger)tag
{
    return [cell viewWithTag: tag];
}

-(id)subCtrlFromIndexPath:(NSIndexPath*)indexPath subCtrl:(NSInteger)tag
{
    UITableViewCell *cell = [self._tableView cellForRowAtIndexPath:indexPath];
    return [self subCtrlFromCell:cell subCtrl:tag];
}

@end
