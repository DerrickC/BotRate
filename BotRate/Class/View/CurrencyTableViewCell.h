//
//  CurrencyTableViewCell.h
//  BotRate
//
//  Created by Tom Hsu on 2014-11-27.
//  Copyright (c) 2014 Tom Hsu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrencyTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *currencyLabel;
@property (nonatomic, weak) IBOutlet UIButton *cashBuying;
@property (nonatomic, weak) IBOutlet UIButton *cashSelling;
@property (nonatomic, weak) IBOutlet UIButton *spotBuying;
@property (nonatomic, weak) IBOutlet UIButton *spotSelling;
@end