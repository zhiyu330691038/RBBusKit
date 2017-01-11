//
//  NSObject+RBDBHandle.h
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/27.
//
//

#import <Foundation/Foundation.h>
#import "RBDBParamHelper.h"
#import "RBDBProtocol.h"


@protocol RBDBProtocol ;

@interface NSObject (RBDBHandle)

@property(nonatomic,assign)int primaryValue;

@property(nonatomic,assign)int superPrimaryValue;


#pragma mark - SQL 语句执行

+ (void)transaction:(NSArray *(^)(void)) block;

+ (void)executeSQL:(NSString *)sql;


#pragma mark - 更新数据

/**
 *  @author 智奎宇, 16-09-28 20:09:49
 *
 *   更新modle数据（新增）
 */
- (void)save;

/**
 *  @author 智奎宇, 16-09-28 20:09:09
 *
 *  批量更新数据
 *
 *  @param array modle 数组
 *  @param param 更新的条件
 */
+ (void)saveArrays:(NSArray <id<RBDBProtocol>> *) array;

#pragma mark - 删除数据

/**
 *  @author 智奎宇, 16-09-28 20:09:39
 *
 *  删除自身modle
 */
- (void)remove;

/**
 *  @author 智奎宇, 16-09-28 20:09:09
 *
 *  删除modle 类型数据
 *
 *  @param param 删除条件
 */
+ (void)removeParam:(RBDBParamHelper *)param;


#pragma mark - 查询数据

/**
 *  @author 智奎宇, 16-09-28 20:09:56
 *
 *  查询所有modle 类型的数据
 */
+ (void)selectAll:(void(^)(NSArray *)) dataBlock;

/**
 *  @author 智奎宇, 16-09-28 20:09:20
 *
 *  查询所有modle 类型的数据
 *
 *  @param param 查询条件
 */
+ (void)selectParam:(RBDBParamHelper *)param :(void(^)(NSArray *)) dataBlock;

@end
