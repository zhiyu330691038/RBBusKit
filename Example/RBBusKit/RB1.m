//
//  RB1.m
//  RBBusKit
//
//  Created by Zhi Kuiyu on 16/9/26.
//  Copyright © 2016年 zhikuiyu. All rights reserved.
//

#import "RB1.h"

@implementation RB1

//不重复的键
//+ (NSArray *) uniqueKeys{
//    return @[@"i"];
//}

//key 包含modle
+ (NSDictionary *) equivalentModle{
    return @{@"arr":@"RBtewtetw"};

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
