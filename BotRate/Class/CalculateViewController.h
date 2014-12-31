//
//  CalculateViewController.h
//  BotRate
//
//  Created by Tom Hsu on 2014-12-03.
//  Copyright (c) 2014 Tom Hsu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Currency.h"

typedef NS_ENUM(NSInteger, CurrencyType) {
    CashBuying,
    CashSelling,
    SpotBuying,
    SpotSelling
};

@interface CalculateViewController : UIViewController
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic, copy) NSArray *currencies;
@property (nonatomic, strong) Currency *selectedCurrency;
@property (nonatomic) CurrencyType currencyType;
@end
