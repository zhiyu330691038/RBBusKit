//
//  RB1.h
//  RBBusKit
//
//  Created by Zhi Kuiyu on 16/9/26.
//  Copyright © 2016年 zhikuiyu. All rights reserved.
//

#import "RBDBProtocol.h"
#import "RBtewtetw.h"
#import "RBTest1.h"

@interface RB1 : NSObject<RBDBProtocol,NSCopying,NSCoding>


@property(nonatomic,assign) int aaa NS_AVAILABLE(10.4, 8.0);
@property(nonatomic,strong,nullable) NSArray  <RBtewtetw *>*arr;
@property(nonatomic,strong,nullable) NSArray *arrtest;
@property (assign, nonatomic) NSInteger i;
@property (assign, nonatomic) CGFloat f;

@end
