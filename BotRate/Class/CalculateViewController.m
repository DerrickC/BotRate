//
//  CalculateViewController.m
//  BotRate
//
//  Created by Tom Hsu on 2014-12-03.
//  Copyright (c) 2014 Tom Hsu. All rights reserved.
//

#import "CalculateViewController.h"

@interface CalculateViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UIPickerView *currencyPicker;
@property (nonatomic, weak) IBOutlet UILabel *selectedCurrencyLabel;
@property (nonatomic, weak) IBOutlet UILabel *currectSelectedRateLabel;
@property (nonatomic, weak) IBOutlet UITextField *currencyTextField;
@property (nonatomic, weak) IBOutlet UITextField *ntdTextField;

@end

@implementation CalculateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIScreenEdgePanGestureRecognizer *leftEdgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    [leftEdgeGesture setEdges:UIRectEdgeLeft];
    [self.view addGestureRecognizer:leftEdgeGesture];
    
    [self.currencyTextField addTarget:self action:@selector(calculateAndUpdateTextFields:) forControlEvents:UIControlEventEditingChanged];
    [self.ntdTextField addTarget:self action:@selector(calculateAndUpdateTextFields:) forControlEvents:UIControlEventEditingChanged];
    
    [self updateUI];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)updateUI {
    self.title = self.selectedCurrency.currency;
    self.selectedCurrencyLabel.text = self.selectedCurrency.currency;
    
    [self.currencyPicker selectRow:self.selectedRow inComponent:0 animated:YES];
    switch (self.currencyType) {
            //現金買入
        case 0:
            [self.currencyPicker selectRow:0 inComponent:1 animated:YES];
            [self.currencyPicker selectRow:0 inComponent:2 animated:YES];
            [self.currectSelectedRateLabel setText:self.selectedCurrency.cashBuying];
            break;
            //現金賣出
        case 1:
            [self.currencyPicker selectRow:0 inComponent:1 animated:YES];
            [self.currencyPicker selectRow:1 inComponent:2 animated:YES];
            [self.currectSelectedRateLabel setText:self.selectedCurrency.cashSelling];
            break;
            //即期買入
        case 2:
            [self.currencyPicker selectRow:1 inComponent:1 animated:YES];
            [self.currencyPicker selectRow:0 inComponent:2 animated:YES];
            [self.currectSelectedRateLabel setText:self.selectedCurrency.spotBuying];
            break;
            //即期賣出
        case 3:
            [self.currencyPicker selectRow:1 inComponent:1 animated:YES];
            [self.currencyPicker selectRow:1 inComponent:2 animated:YES];
            [self.currectSelectedRateLabel setText:self.selectedCurrency.spotSelling];
            break;
        default:
            break;
    }
}
- (IBAction)dismissKeyboard:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
}

- (void)calculateAndUpdateTextFields:(UITextField *)textField {
    if ([self checkRateLabelTextIfIsDoubleValue]) {
        //Foreign to NTD
        if ([textField isEqual:self.currencyTextField]) {
            double result = [textField.text doubleValue] * [self.currectSelectedRateLabel.text doubleValue];
            self.ntdTextField.text = [NSString stringWithFormat:@"%.2f", result];
        }
        //NTD to Foreign
        else {
            double result = [textField.text doubleValue] / [self.currectSelectedRateLabel.text doubleValue];
            self.currencyTextField.text = [NSString stringWithFormat:@"%.2f", result];
        }
    }
}
- (BOOL)checkRateLabelTextIfIsDoubleValue {
    NSScanner *scanner = [NSScanner scannerWithString:self.currectSelectedRateLabel.text];
    double val = [self.currectSelectedRateLabel.text doubleValue];
    return ([scanner scanDouble:&val] && [scanner isAtEnd]);
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (component) {
        case 0:
            return self.currencies.count;
            break;
        case 1:
        case 2:
            return 2;
            break;
        default:
            return 0;
            break;
    }
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (component) {
        case 0:
            return ((Currency *)self.currencies[row]).currency;
            break;
        case 1:
            if (row == 0) {
                return @"現金";
            }
            else {
                return @"即期";
            }
            break;
        case 2:
            if (row == 0) {
                return @"買入";
            }
            else {
                return @"賣出";
            }
            break;
        default:
            return nil;
            break;
    }
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedCurrency = [self.currencies objectAtIndex:[pickerView selectedRowInComponent:0]];
    self.selectedRow = [self.currencyPicker selectedRowInComponent:0];
    self.selectedCurrencyLabel.text = self.selectedCurrency.currency;
    self.currencyType = (((int)[pickerView selectedRowInComponent:1] << 1) + ((int)[pickerView selectedRowInComponent:2]));

    [self updateUI];

    if ([self.currencyTextField isFirstResponder]) {
        [self calculateAndUpdateTextFields:self.currencyTextField];
    }
    else {
        [self calculateAndUpdateTextFields:self.ntdTextField];
    }
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    switch (component) {
        case 0:
            return 180;
            break;
        case 1:
            return 65;
            break;
        case 2:
            return 65;
            break;
        default:
            return 0;
            break;
    }
}
@end
