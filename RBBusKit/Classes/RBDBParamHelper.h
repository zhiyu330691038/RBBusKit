//
//  RBDBParamHelper.h
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/28.
//
//

#import <Foundation/Foundation.h>

#define HKey(arg) (@""#arg)


@class RBDBParamHelper;

@interface RBDBTerm : NSObject
@property(nonatomic,weak) RBDBParamHelper * dbHelper;

- (RBDBParamHelper * (^)()) AND;

- (RBDBParamHelper * (^)()) OR;


@end


@class RBDBComple;


@interface RBDBComple : NSObject
@property(nonatomic,assign) BOOL isStringType;
@property(nonatomic,weak) RBDBParamHelper * dbHelper;
- (RBDBTerm * (^)(NSObject *)) equal;
- (RBDBTerm * (^)(NSObject *)) unEqual;
- (RBDBTerm * (^)(NSObject *)) lessThan;
- (RBDBTerm * (^)(NSObject *)) greaterThan;
- (RBDBTerm * (^)(NSString *)) prefix;
- (RBDBTerm * (^)(NSString *)) suffix;
- (RBDBTerm * (^)(NSString *)) contain;
@end






@interface RBDBParamHelper : NSObject



typedef NS_ENUM(NSInteger,RBDBSortType){
    ASC, //升序
    DESC //降序
};

typedef NS_ENUM(NSInteger,RBDBEqualType){
    EQUAL,  //相等
    UNQUAL, //不相等
    LessThan,//小于
    GreaterThan,//大于
};

typedef NS_ENUM(NSInteger,RBDBFilterType){
    ALL,        //包含
    Prefix,     //向后匹配
    Suffix,     //向前匹配
};


- (id)initModleClass:(Class)mclass;

- (id)init __attribute__((unavailable("alloc not available, call sharedInstance instead")));  ;

- (NSString *)getTerm;

- (void)appendParam:(NSString *)str;

#pragma mark - 查询条件，可添加多个条件

/**
 *  @author 智奎宇, 16-09-28 11:09:56
 *
 *  条件查询
 *
 *  @param key   modle 成员变量
 */
- (RBDBComple * (^)(id key)) comple;

#pragma mark - 排序条件，可添加多个条件
/**
 *  @author 智奎宇, 16-09-28 11:09:56
 *
 *  排序
 *
 *  @param key   modle 成员变量
 *  @param type  要排序的方式
 */
- (RBDBParamHelper * (^)(id key,RBDBSortType type)) sort;

#pragma mark - 返回数量,不执行默认返回全部

/**
 *  @author 智奎宇, 16-09-28 11:09:56
 *
 *  查询数量
 *
 *  @param key   count 返回数量
 */
- (RBDBParamHelper * (^)(NSUInteger)) count;


@end
