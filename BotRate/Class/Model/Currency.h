//
//  Currency.h
//  BotRate
//
//  Created by Tom Hsu on 2014-12-08.
//  Copyright (c) 2014 Tom Hsu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Currency : NSManagedObject

@property (nonatomic, retain) NSString * cashBuying;
@property (nonatomic, retain) NSString * cashSelling;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * spotBuying;
@property (nonatomic, retain) NSString * spotSelling;

@end
