//
//  RBDBParamHelper.m
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/28.
//
//

#import "RBDBParamHelper.h"
#import <objc/runtime.h>
#import "NSObject+RBTools.h"

@implementation RBDBComple


- (RBDBTerm * (^)(NSObject * )) equal{
    return ^RBDBTerm * (NSObject * value){
        [self.dbHelper appendParam:@" == "];
        return [self getResult:value];
    };
}

- (RBDBTerm * (^)(NSObject * )) unEqual{
    return ^RBDBTerm * (NSObject * value){
        [self.dbHelper appendParam:@" <> "];
        return [self getResult:value];
    };
}

- (RBDBTerm * (^)(NSObject * )) lessThan{
    return ^RBDBTerm * (NSObject * value){
        [self.dbHelper appendParam:@" < "];
        return [self getResult:value];
    };
}
- (RBDBTerm * (^)(NSObject * )) greaterThan{
    return ^RBDBTerm * (NSObject * value){
        [self.dbHelper appendParam:@" > "];
        return [self getResult:value];
    };
}

- (RBDBTerm * (^)(NSString *)) prefix{
    return ^RBDBTerm * (NSObject * value){
        [self.dbHelper appendParam:@" like "];
        if(!self.isStringType){
            NSLog(@"不是字符类性，无法匹配");
            return nil;
        }
        [self.dbHelper appendParam:[NSString stringWithFormat:@"'%@%%%%'",value]];
        RBDBTerm * comple = [[RBDBTerm alloc] init];
        comple.dbHelper = self.dbHelper;
        return comple;

    };
}
- (RBDBTerm * (^)(NSString *)) contain{
    return ^RBDBTerm * (NSObject * value){
        [self.dbHelper appendParam:@" like "];
        if(!self.isStringType){
            NSLog(@"不是字符类性，无法匹配");
            return nil;
        }
        [self.dbHelper appendParam:[NSString stringWithFormat:@"'%%%%%@%%%%'",value]];
        RBDBTerm * comple = [[RBDBTerm alloc] init];
        comple.dbHelper = self.dbHelper;
        return comple;
    };
}
- (RBDBTerm * (^)(NSString *)) suffix{
    return ^RBDBTerm * (NSObject * value){
        [self.dbHelper appendParam:@" like "];
        if(!self.isStringType){
            NSLog(@"不是字符类性，无法匹配");
            return nil;
        }
        
        [self.dbHelper appendParam:[NSString stringWithFormat:@"'%%%%%@'",value]];
        RBDBTerm * comple = [[RBDBTerm alloc] init];
        comple.dbHelper = self.dbHelper;
        return comple;
    };
}


- (RBDBTerm *)getResult:(NSObject *)value{

    [self.dbHelper appendParam:self.isStringType ? [NSString stringWithFormat:@"'%@'",value] : value];
    RBDBTerm * comple = [[RBDBTerm alloc] init];
    comple.dbHelper = self.dbHelper;
    return comple;
}

@end


@implementation RBDBTerm

- (RBDBParamHelper * (^)()) AND{
    return ^RBDBParamHelper * (){
        [self.dbHelper appendParam:@" AND "];
        return self.dbHelper;
    };
}


- (RBDBParamHelper * (^)()) OR{
    return ^RBDBParamHelper * (){
        [self.dbHelper appendParam:@" OR "];
        return self.dbHelper;
    };
}

@end



@interface RBDBParamHelper(){
    
    NSMutableString * whereParam;
    
    NSMutableArray * orderBy;
    
    NSString       * limit;
    
    Class           modleClass;
}




@end

@implementation RBDBParamHelper



#pragma mark - private memthod


- (id)initModleClass:(Class)mclass{
    if(self = [super init]){
        modleClass = mclass;
      
        whereParam = [NSMutableString new];
        
        orderBy = [NSMutableArray new];
    }
    return self;
}

- (void)appendParam:(NSString *)str{
    [whereParam appendFormat:[NSString stringWithFormat:@"%@",str]];
}

- (NSString *)getTerm{
    
    NSMutableString * where = [NSMutableString new];
  
    if([whereParam length] > 0){
        [whereParam insertString:@"WHERE " atIndex:0];
    }
    if([orderBy count] > 0){
        [whereParam appendFormat:@" ORDER BY %@ ",[orderBy componentsJoinedByString:@","]];
    }
    
    if(limit){
        [whereParam appendFormat:@" LIMIT %@",limit];
    }
    
    return whereParam;
}


- (void)markOrderBy:(NSString *)keya SortType:(RBDBSortType)type{
    NSArray * key = [[keya componentsSeparatedByString:@"."] lastObject];
    [orderBy addObject:[NSString stringWithFormat:@" %@ %@",key , type == ASC ? @"ASC" :@"DESC"]];
}


#pragma mark - 查询条件，可添加多个条件

/**
 *  @author 智奎宇, 16-09-28 11:09:56
 *
 *  条件查询
 *
 *  @param key   modle 成员变量
 *  @param value 要比较的值
 *  @param type  要比较的方式
 */
- (RBDBComple * (^)(id key)) comple{
    return ^RBDBComple * (id fullkey){
        NSArray * key ;
        if([fullkey containsString:@"."]){
            key = [[fullkey componentsSeparatedByString:@"."] lastObject];
        }else{
            key =fullkey;
        }
        
        NSDictionary * dict = [modleClass infoWithInstance:key];
        if(dict == nil){
            NSString * str = [NSString stringWithFormat:@"%@ 不存此变量",[modleClass description]];
            NSAssert(dict != nil, @"");
            return nil;
        }
        NSString * name = dict[@"name"];
        NSString * property = dict[@"property"];
        [whereParam appendFormat:@" %@ ", name];
        RBDBComple * help = [[RBDBComple alloc] init];
        help.dbHelper = self;
        if([[[self class] ocTypeToSql:property] isEqualToString:@"TEXT"]){
            help.isStringType = YES;
        }
        return help;
    };
}

#pragma mark - 排序条件，可添加多个条件
/**
 *  @author 智奎宇, 16-09-28 11:09:56
 *
 *  排序
 *
 *  @param key   modle 成员变量
 *  @param type  要排序的方式
 */
- (RBDBParamHelper * (^)(id key,RBDBSortType type)) sort{
    return ^RBDBParamHelper * (id   key,RBDBSortType type){
        [self markOrderBy:key SortType:type];
        return self;
    };
}

#pragma mark - 返回数量,不执行默认返回全部

/**
 *  @author 智奎宇, 16-09-28 11:09:56
 *
 *  查询数量
 *
 *  @param key   count 返回数量
 */
- (RBDBParamHelper * (^)(NSUInteger)) count{
    return ^RBDBParamHelper * (NSUInteger count){
        limit = [NSString stringWithFormat:@"%d",count];
        return self;
    };
}





@end
