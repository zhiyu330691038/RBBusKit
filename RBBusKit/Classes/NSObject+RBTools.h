//
//  NSObject+RBTools.h
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/27.
//
//

#import <Foundation/Foundation.h>




@interface NSObject (RBTools)



/**
 *  @author 智奎宇, 16-09-26 21:09:13
 *
 *  数据库版本号
 *
 */
+ (NSUInteger)dbVersion ;

/**
 *  @author 智奎宇, 16-09-26 21:09:09
 *
 *  表的版本号
 *
 *  @return 表版本号
 */
+ (NSUInteger)tbVersion;


+ (NSDictionary *)infoWithInstance:(NSString *)instanceName;
/**
 *  @author 智奎宇, 16-09-28 11:09:54
 *
 *  获取所有属性
 *
 */
+ (NSArray *)getAllProperties;
/**
 *  @author 智奎宇, 16-09-26 17:09:05
 *
 *  获取类所有property 类型变量名称
 *
 *  @return
 */
+ (NSArray *)getAllPropertiesNamed;

/**
 *  @author 智奎宇, 16-09-29 12:09:41
 *
 *  runtime 类型转化oc 类型
 *
 *  @param property T@
 *
 */
+ (NSString *)runToOCType:(NSString *)property;
/**
 *  @author 智奎宇, 16-09-29 12:09:10
 *
 *  oc 类型对应成 sql 类型
 *
 *  @param type
 *
 *  @return
 */
+ (NSString *)ocTypeToSql:(NSString *)type;



@end
