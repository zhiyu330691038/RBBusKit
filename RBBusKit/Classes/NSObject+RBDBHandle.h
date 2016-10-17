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


/**
 *  @author 智奎宇, 16-09-29 21:09:24
 *
 *  只设置默认类型主键
 *
 */
- (void)setPrimaryValue:(NSObject *)obj;

- (NSObject *)primaryValue;

+ (void)changeCopyMethod;

#pragma mark - SQL 语句执行

+ (void)transaction:(NSArray *(^)(void)) block;

+ (void)executeSQL:(NSString *)sql;


#pragma mark - 保存数据

/**
 *  @author 智奎宇, 16-09-28 20:09:49
 *
 *   保存modle数据（新增）
 */
- (void)save;

/**
 *  @author 智奎宇, 16-09-28 20:09:33
 *
 *  保存modle数据（新增）
 *
 *  @param param 新增数据的条件
 */
- (void)saveParam:(RBDBParamHelper *)param;

/**
 *  @author 智奎宇, 16-09-28 20:09:09
 *
 *  批量保存数据
 *
 *  @param array modle 数组
 *  @param param 保存的条件
 */
+ (void)save:(NSArray <id<RBDBProtocol>> *) array Param:(RBDBParamHelper *)param;

#pragma mark - 删除数据

/**
 *  @author 智奎宇, 16-09-28 20:09:39
 *
 *  删除自身modle
 */
- (void)remove;

/**
 *  @author 智奎宇, 16-09-28 20:09:49
 *
 *  删除所有modle 类型数据
 */
+ (void)removeAll;

/**
 *  @author 智奎宇, 16-09-28 20:09:09
 *
 *  删除modle 类型数据
 *
 *  @param param 删除条件
 */
+ (void)removeParam:(RBDBParamHelper *)param;

#pragma mark - 更新数据

/**
 *  @author 智奎宇, 16-09-28 20:09:28
 *
 *  modle 数据更新
 */
- (void)update;

/**
 *  @author 智奎宇, 16-09-28 20:09:41
 *
 *  数据更新
 *
 *  @param param 数据更新条件
 */
- (void)updateParam:(RBDBParamHelper *)param;

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
