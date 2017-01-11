//
//  RBtewtetw.m
//  RBBusKit
//
//  Created by Zhi Kuiyu on 16/9/27.
//  Copyright © 2016年 zhikuiyu. All rights reserved.
//

#import "RBtewtetw.h"

@implementation RBtewtetw
+ (NSString *)primary{
    return @"aaa";
}

+ (NSDictionary *) equivalentModle{
    return @{@"arr1":@"RBTest1"};
    
}
#pragma mark ------------------- 解析部分 ------------------------
//归档
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self modelEncodeWithCoder:aCoder];
}
//解档
- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    return  [self modelInitWithCoder:aDecoder];
}

//打印
-(NSString *)description{
    return [self modelDescription];
}

//拷贝
-(id)copyWithZone:(NSZone *)zone{
    return [self modelCopy];
}

@end
