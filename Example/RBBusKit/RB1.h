//
//  RB1.h
//  RBBusKit
//
//  Created by Zhi Kuiyu on 16/9/26.
//  Copyright © 2016年 zhikuiyu. All rights reserved.
//

#import "RBDBProtocol.h"
#import "RBtewtetw.h"


@interface RB1 : NSObject<RBDBProtocol>


@property(nonatomic,assign) int aaa NS_AVAILABLE(10.4, 8.0);
@property(nonatomic,assign) float aaaa NS_AVAILABLE(10.4, 8.0);
@property(nonatomic,assign) double fdas NS_AVAILABLE(10.4, 8.0);
@property(nonatomic,strong) NSString * teaa;
@property(nonatomic,strong) NSString * taa;
@property(nonatomic,strong) NSString * taaa;
@property(nonatomic,strong) NSString * tedaa;
@property(nonatomic,strong) NSNumber * aba;
@property(nonatomic,strong) NSDate * adta;
@property(nonatomic,strong) NSData * data;
@property(nonatomic,strong) RBtewtetw * modle;
@property(nonatomic,strong,nullable) NSArray  *arr;
@property(nonatomic,strong) UIImage * image;
@property (assign, nonatomic) NSInteger i;
@property (assign, nonatomic) CGFloat f;

@end
