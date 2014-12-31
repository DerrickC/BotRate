//
//  RateTableViewController.m
//  BotRate
//
//  Created by Tom Hsu on 2014-11-26.
//  Copyright (c) 2014 Tom Hsu. All rights reserved.
//

#import <TFHpple.h>

#import "Currency.h"
#import "QuotedDate.h"

#import "QuotedDateSectionHeaderView.h"
#import "RateTitleSectionHeaderView.h"
#import "CopyRightSectionFooterView.h"
#import "CurrencyTableViewCell.h"

#import "RateTableViewController.h"
#import "CalculateViewController.h"


@interface RateTableViewController ()
@property (nonatomic, strong) TFHpple *parser;
@property (nonatomic, strong) NSMutableArray *currencies;
@property (nonatomic, strong) NSString *quotedDateString;

@property (nonatomic, strong) QuotedDate *quotedDate;
@end

@implementation RateTableViewController

#pragma mark - View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"QuotedDateSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"QuotedDateSectionHeaderView"];
    [self.tableView registerNib:[UINib nibWithNibName:@"RateTitleSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"RateTitleSectionHeaderView"];
    [self.tableView registerNib:[UINib nibWithNibName:@"CopyRightSectionFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"CopyRightSectionFooterView"];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem.title = @"編輯";
    
    self.currencies = [[NSMutableArray alloc] initWithCapacity:20];
    [self fetchData];
    [self loadRateData];
}
- (void)viewWillDisappear:(BOOL)animated {
    [self.refreshControl endRefreshing];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadRateData {
    NSURL *botBankRateURL = [NSURL URLWithString:@"http://rate.bot.com.tw/Pages/Static/UIP003.zh-TW.htm"];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:botBankRateURL]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               if (httpResponse.statusCode == 200) {
                                   if (data) {
                                       self.parser = [TFHpple hppleWithHTMLData:data];
                                       
                                       [self setRefreshControlUpdateTime];
                                       [self parseQuotedDate];
                                       [self parseCurrencyData];
                                       
                                       [self.tableView reloadData];
                                   }
                               }
                               else {
                                   [self.refreshControl endRefreshing];
                               }
                           }];
    
}
- (IBAction)currencyButtonTap:(UIButton *)btn {
    [self performSegueWithIdentifier:@"Calculate" sender:btn];
    [self setEditing:NO animated:NO];
}
- (void)botBankButtonPress {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.bot.com.tw/"]];
}
- (void)setRefreshControlUpdateTime {
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, HH:mm:ss"];
    NSString *lastupdated = [NSString stringWithFormat:@"上次更新時間: %@",[formattedDate stringFromDate:[NSDate date]]];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:lastupdated];
    [self.refreshControl endRefreshing];
}
- (void)parseQuotedDate {
    NSString *quotedDateQueryString = @"//td[@style='width:326px;text-align:left;vertical-align:top;color:#0000FF;font-size:11pt;font-weight:bold;']";
    NSArray *nodes = [self.parser searchWithXPathQuery:quotedDateQueryString];
    
    if (self.quotedDate.dateString) {
        [self updateQuotedDateWithNodes:nodes];
    }
    else {
        [self insertQuotedDateWithNodes:nodes];
    }
}
- (void)parseCurrencyData {
    NSString *currencyDateQueryString = @"//table[@title='牌告匯率']/tr[@class]";
    NSArray *nodes = [self.parser searchWithXPathQuery:currencyDateQueryString];
    
    if (self.currencies.count > 0) {
        [self updateRateDataWithNodes:nodes];
    }
    else {
        [self insertRateDataWithNodes:nodes];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        self.navigationItem.leftBarButtonItem.title = @"完成";
    }
    else {
        self.navigationItem.leftBarButtonItem.title = @"編輯";
    }
}

#pragma mark - Core Data
- (void)fetchData {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSError *error;
    NSEntityDescription *entity;
    NSArray *array;
    
    //Quoted Date Data
    entity = [NSEntityDescription entityForName:@"QuotedDate" inManagedObjectContext:self.context];
    [request setEntity:entity];
    array = [self.context executeFetchRequest:request error:&error];
    if (array.count) {
        self.quotedDate = array[0];
        self.quotedDateString = [NSString stringWithFormat:@"牌價最新掛牌時間: %@", self.quotedDate.dateString];
    }
    
    //Currency Rate Data
    entity = [NSEntityDescription entityForName:@"Currency" inManagedObjectContext:self.context];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [request setEntity:entity];
    [request setSortDescriptors:@[sortDescriptor]];
    array = [self.context executeFetchRequest:request error:&error];
    if (array.count) {
        self.currencies = [array mutableCopy];
    }
}
- (void)insertRateDataWithNodes:(NSArray *)nodes {
    for (int i=0; i<nodes.count; i++) {
        TFHppleElement *element = nodes[i];
        
        Currency *currency = [NSEntityDescription insertNewObjectForEntityForName:@"Currency"
                                                           inManagedObjectContext:self.context];
        currency.currency = ((TFHppleElement *)((TFHppleElement *)element.children[0]).children[1]).content;
        currency.cashBuying = ((TFHppleElement *)((TFHppleElement *)element.children[1]).children[0]).content;
        currency.cashSelling = ((TFHppleElement *)((TFHppleElement *)element.children[2]).children[0]).content;
        currency.spotBuying = ((TFHppleElement *)((TFHppleElement *)element.children[3]).children[0]).content;
        currency.spotSelling = ((TFHppleElement *)((TFHppleElement *)element.children[4]).children[0]).content;
        currency.order = [NSNumber numberWithInt:i];
        
        [self.currencies addObject:currency];
    }
    [self saveContext];
}
- (void)updateRateDataWithNodes:(NSArray *)nodes {
    for (int i=0; i<nodes.count; i++) {
        TFHppleElement *element = nodes[i];
        
        NSString *currencyName = ((TFHppleElement *)((TFHppleElement *)element.children[0]).children[1]).content;
        for (Currency *currency in self.currencies) {
            if ([currency.currency isEqualToString:currencyName]) {
                currency.cashBuying = ((TFHppleElement *)((TFHppleElement *)element.children[1]).children[0]).content;
                currency.cashSelling = ((TFHppleElement *)((TFHppleElement *)element.children[2]).children[0]).content;
                currency.spotBuying = ((TFHppleElement *)((TFHppleElement *)element.children[3]).children[0]).content;
                currency.spotSelling = ((TFHppleElement *)((TFHppleElement *)element.children[4]).children[0]).content;
            }
        }
    }
    
    [self saveContext];
}
- (void)insertQuotedDateWithNodes:(NSArray *)nodes {
    TFHppleElement *element = ((TFHppleElement *)nodes[0]).children[2];
    
    NSString *dateString = [element.content substringWithRange:NSMakeRange(27, 16)];
    if (dateString) {
        self.quotedDate = [NSEntityDescription insertNewObjectForEntityForName:@"QuotedDate"
                                                        inManagedObjectContext:self.context];
        self.quotedDate.dateString = dateString;
        self.quotedDateString = [NSString stringWithFormat:@"牌價最新掛牌時間: %@", self.quotedDate.dateString];
    }
    [self saveContext];
}
- (void)updateQuotedDateWithNodes:(NSArray *)nodes {
    TFHppleElement *element = ((TFHppleElement *)nodes[0]).children[2];
    
    NSString *dateString = [element.content substringWithRange:NSMakeRange(27, 16)];
    if (dateString) {
        self.quotedDate.dateString = dateString;
        self.quotedDateString = [NSString stringWithFormat:@"牌價最新掛牌時間: %@", self.quotedDate.dateString];
    }
    [self saveContext];
}
- (void)saveContext {
    NSError *error;
    if (![self.context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0) {
        return 0;
    }
    if (section==1) {
        return self.currencies.count;
    }
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CurrencyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rateExchangeCell" forIndexPath:indexPath];
    // Configure the cell...
    Currency *currency = self.currencies[indexPath.row];
    cell.currencyLabel.text = currency.currency;
    [cell.cashBuying setTitle:currency.cashBuying forState:UIControlStateNormal];
    [cell.cashSelling setTitle:currency.cashSelling forState:UIControlStateNormal];
    [cell.spotBuying setTitle:currency.spotBuying forState:UIControlStateNormal];
    [cell.spotSelling setTitle:currency.spotSelling forState:UIControlStateNormal];
    
    if (indexPath.row % 2) {
        cell.cashBuying.backgroundColor = cell.cashSelling.backgroundColor = cell.spotBuying.backgroundColor = cell.spotSelling.backgroundColor = [UIColor colorWithWhite:0.980 alpha:1.000];
    }
    else {
        cell.cashBuying.backgroundColor = cell.cashSelling.backgroundColor = cell.spotBuying.backgroundColor = cell.spotSelling.backgroundColor = [UIColor colorWithRed:0.961 green:0.882 blue:0.929 alpha:1.000];
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        QuotedDateSectionHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"QuotedDateSectionHeaderView"];
        if (self.quotedDateString) {
            header.quotedDateLabel.text = self.quotedDateString;
        }
        
        return header;
    }
    if (section == 1) {
        RateTitleSectionHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"RateTitleSectionHeaderView"];
        return header;
    }
    return nil;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) {
        CopyRightSectionFooterView *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"CopyRightSectionFooterView"];
        [footer.botBankBtn addTarget:self action:@selector(botBankButtonPress) forControlEvents:UIControlEventTouchUpInside];
        return footer;
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 21;
    }
    if (section == 1) {
        return 65;
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return 23;
    }
    return 0;
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    Currency *currency = self.currencies[sourceIndexPath.row];
    [self.currencies removeObject:currency];
    [self.currencies insertObject:currency atIndex:destinationIndexPath.row];
    
    for (int i=0; i<self.currencies.count; i++) {
        Currency *currency = self.currencies[i];
        currency.order = [NSNumber numberWithInt:i];
    }
    
    [self saveContext];
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}
- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.section != sourceIndexPath.section) {
        return sourceIndexPath;
    }
    return proposedDestinationIndexPath;
}

#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UIButton *)btn {
    if ([[segue identifier] isEqualToString:@"Calculate"]) {
        CGPoint pointInTable = [btn convertPoint:btn.bounds.origin toView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pointInTable];
        
        CalculateViewController *vc = [segue destinationViewController];
        vc.selectedCurrency = self.currencies[indexPath.row];
        vc.currencies = [self.currencies copy];
        vc.selectedRow = indexPath.row;
        vc.currencyType = btn.tag;
    }
}

@end
