//
//  RBTest1.h
//  RBBusKit
//
//  Created by kieran on 2017/1/6.
//  Copyright © 2017年 zhikuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBDBProtocol.h"

@interface RBTest1 : NSObject<RBDBProtocol,NSCopying,NSCoding>

@property (nonatomic,strong) NSString * name;

@end
