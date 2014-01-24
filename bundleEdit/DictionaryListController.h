//
//  DictionaryListController.h
//  bundleEdit
//
//  Created by Pete on 12.02.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingTableView.h"

@protocol DataSinkProtocol <NSObject>

-(void)saveFile;

@end

@interface DictionaryListController : UIViewController
<UISearchDisplayDelegate,
UITableViewDataSource,UITableViewDelegate,
UIActionSheetDelegate,
UITextFieldDelegate> {
    enum {
        scEditKey=1,scEditValue,scButtonType,scButtonEdit
    } CellSubControls;
    
    enum {
        typeArray,typeDictionary,typeString,typeBoolean,typeInteger,typeDate
    } ValueTypes;

    TPKeyboardAvoidingTableView *_tableView;
    UITableViewCell *_valueCell;
    UIToolbar *_toolBar;
    NSIndexPath *_currentIndexPath;
    NSArray *_typeArray;
   // NSArray *_resList;
    id _dict;
    id _resList;
    id<DataSinkProtocol> _firstViewController;
    NSDateFormatter *_dateFormatter;
    BOOL _searchMode;
}

@property(nonatomic,retain) id _firstViewController;
@property(nonatomic,retain) IBOutlet TPKeyboardAvoidingTableView *_tableView;
@property(nonatomic,retain) IBOutlet UITableViewCell *_valueCell;
@property(nonatomic,retain) IBOutlet UIToolbar *_toolBar;

-(id) initWithDictionary:(NSMutableDictionary*)otherDictionary;
-(UITableViewCell*) cellFromSubControl:(id)sub;
-(id)subCtrlFromCell:(UITableViewCell*)cell subCtrl:(NSInteger)tag;
-(id)subCtrlFromIndexPath:(NSIndexPath*)indexPath subCtrl:(NSInteger)tag;
-(NSMutableDictionary*)asDictionary:(BOOL)isSearch;
-(NSMutableArray*)asArray:(BOOL)isSearch;
-(NSString*)getKeyStringAt:(NSInteger)index forMode:(BOOL)isSearch;
-(id)getValueObjectAt:(NSInteger)index forMode:(BOOL)isSearch;
-(BOOL)isArray:(BOOL)isSearch;
-(void)updateValues:(id)sender;

-(IBAction)onSelectType:(id)sender;
-(IBAction)onEditValue:(id)sender;
-(IBAction)onBeginEdit:(id)sender;
-(IBAction)onDone:(id)sender;
-(IBAction)onEditingDone:(id)sender;
-(IBAction)onEditClicked:(id)sender;
-(IBAction)onAddClicked:(id)sender;

@end
