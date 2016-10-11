//
//  NSObject+RBDBHandle.m
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/27.
//
//

#import "NSObject+RBDBHandle.h"
#import <FMDB/FMDB.h>
#import "NSObject+RBTools.h"
#import "NSObject+RBDBVersionManager.h"
#import "objc/runtime.h"
#import "NSObject+Helper.h"

@implementation NSObject (RBDBHandle)

#pragma mark - 获取数据库实例

FMDatabaseQueue * DBQueue(){
    static FMDatabaseQueue * dataQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *Paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path=[Paths objectAtIndex:0];
        NSString * dbPath = [path stringByAppendingString:@"/userinfo.sqlite"];
        NSLog(@"%@",dbPath);
        
//        dbPath = @"/Users/zky/Desktop/PuddingPlus/userinfo.sqlite";
        dataQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    });
    return dataQueue;
}

+ (NSString *)primary{

    if([self instancesRespondToSelector:@selector(primary)]){
        return [self primary];
    }
    
    return @"private";
}

+ (bool)primaryKeyObjVar{
    static BOOL isHas;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray * array = [self getAllPropertiesNamed];
        isHas = [array containsObject:[self primary]];
    });
    
    return isHas;
    

}


- (void)setPrimaryValue:(int)obj{
    objc_setAssociatedObject(self, @"primaryValue", @(obj), OBJC_ASSOCIATION_ASSIGN);
}

- (int)primaryValue{

    return [objc_getAssociatedObject(self, @"primaryValue") intValue];
}

#pragma mark - SQL 语句执行


+ (void)transaction:(NSArray *(^)(void)) block{

    if(block){
        NSLog(@"%@",[NSDate date]);

        [DBQueue() inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSArray * sqlArray = block();
            for(NSString * str in sqlArray){
                [db executeUpdate:str];
            }
        }];
        NSLog(@"%@",[NSDate date]);

    }
}


+ (void)executeSQL:(NSString *)sql{
    if(sql){
        [DBQueue() inDatabase:^(FMDatabase *db) {
            [db executeUpdate:sql];
        }];

    }
}

#pragma mark - 

- (NSString *)getCheckIsMyStr{
    BOOL is = [[self class] primaryKeyObjVar];
    NSString * sql ;
    if(is){
        NSArray * array = [[self class] getAllProperties];
        NSString * primaryType = nil;
        for(NSDictionary * dict in array){
            if([[dict objectForKey:@"name"] isEqualToString:[[self class] primary]]){
                primaryType = [dict objectForKey:@"property"];
                break;
            }
        }
        NSObject * value = [self valueForKey:[[self class] primary]];
        
        if([value isKindOfClass:[NSNumber class]]){
        }else if([value isKindOfClass:[NSString class]]){
            value = [NSString stringWithFormat:@"'%@'",value];
        }else{
            return nil;
        }
        return [NSString stringWithFormat:@" %@ == %@", [[self class] primary],value];
    }else{
        return  sql = [NSString stringWithFormat:@" %@ == %@", [[self class] primary],@([self primaryValue])];
    }


}


+ (NSDictionary *)getSql:(RBDBParamHelper *)param ObjInfos:(NSDictionary *)dict{
    __block NSString * tableName = [[self class] getTableName];
    if([dict count] == 0){
        NSLog(@"data is nil");
        return nil;
    }
    NSArray * keys = [dict allKeys];
    NSMutableString * sql = [NSMutableString new];
    [sql appendFormat:@"INSERT INTO %@ ",tableName];
    [sql appendFormat:@"(%@) ",[keys componentsJoinedByString:@","]];
    NSMutableArray * pos  =[NSMutableArray new];
    
    NSMutableDictionary * values = [NSMutableDictionary new];
    for(NSString * key in keys){
        NSObject * obj = [dict objectForKey:key];
        if([obj isKindOfClass:[NSNumber class]]){
            [values setObject:obj forKey:key];
            [pos addObject:[NSString stringWithFormat:@":%@",key]];
        }else{
            if([obj isKindOfClass:[UIImage class]]){
                [values setObject:UIImagePNGRepresentation(obj) forKey:key];
                [pos addObject:[NSString stringWithFormat:@":%@",key]];
            }else if([obj isKindOfClass:[NSDate class]]){
                [values setObject:@([(NSDate *)obj timeIntervalSince1970]) forKey:key];
                [pos addObject:[NSString stringWithFormat:@":%@",key]];
            }else{
                [values setObject:obj forKey:key];
                [pos addObject:[NSString stringWithFormat:@":%@",key]];
                
            }
        }
    }
    [sql appendFormat:@"VALUES (%@)",[pos componentsJoinedByString:@","]];
    NSLog(@"%@",sql);
    
    if(param){
        NSString * where = [param getTerm];
        if(where)
            sql = [NSString stringWithFormat:@"%@ %@",sql,where];
    }
    
    return @{@"sql":sql,@"value":values};
}

#pragma mark - 保存数据

/**
 *  @author 智奎宇, 16-09-28 20:09:49
 *
 *   保存modle数据（新增）
 */
- (void)save{
    [self saveParam:nil];
}

/**
 *  @author 智奎宇, 16-09-28 20:09:33
 *
 *  保存modle数据（新增）
 *
 *  @param param 新增数据的条件
 */
- (void)saveParam:(RBDBParamHelper *)param{
    NSDictionary * dict = [self toDict];

   __block NSDictionary * sqlino =  [[self class] getSql:param ObjInfos:dict];
    
    [DBQueue() inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sqlino[@"sql"] withParameterDictionary:sqlino[@"value"]];
        if(![[self class] primaryKeyObjVar]){
            [self setPrimaryValue:[db lastInsertRowId]];
        }
        
    }];
}

/**
 *  @author 智奎宇, 16-09-28 20:09:09
 *
 *  批量保存数据
 *
 *  @param array modle 数组
 *  @param param 保存的条件
 */
+ (void)save:(NSArray <id<RBDBProtocol>> *) array Param:(RBDBParamHelper *)param{
    [DBQueue() inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for(NSObject * obj in array){
            NSDictionary * dict = [obj toDict];
            __block NSDictionary * sqlino =  [[self class] getSql:param ObjInfos:dict];
            [db executeUpdate:sqlino[@"sql"] withParameterDictionary:sqlino[@"value"]];
            if(![self primaryKeyObjVar]){
                [obj setPrimaryValue:[db lastInsertRowId]];
            }
        }
    }];
}


/**
 *  @author 智奎宇, 16-09-28 20:09:39
 *
 *  删除自身modle
 */
- (void)remove{
    NSString * checkMy = [self getCheckIsMyStr];
    
    if(checkMy){
       NSString * sql = [NSString stringWithFormat:@"DELETE FROM %@ where %@",[[self class] getTableName], checkMy];
        [DBQueue() inDatabase:^(FMDatabase *db) {
            [db executeUpdate:sql];
        }];
        
    }else{
        NSLog(@"移除数据异常");
    }
    
   
}

/**
 *  @author 智奎宇, 16-09-28 20:09:49
 *
 *  删除所有modle 类型数据
 */
+ (void)removeAll{
    NSString * sql = [NSString stringWithFormat:@"DELETE FROM %@",[[self class] getTableName]];
    [DBQueue() inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sql];
    }];

}

/**
 *  @author 智奎宇, 16-09-28 20:09:09
 *
 *  删除modle 类型数据
 *
 *  @param param 删除条件
 */
+ (void)removeParam:(RBDBParamHelper *)param{

    NSString * sql = [NSString stringWithFormat:@"DELETE FROM %@",[[self class] getTableName]];
    if(param){
        NSString * where = [param getTerm];
        if(where)
            sql = [NSString stringWithFormat:@"%@ %@",sql,where];
    }
    [DBQueue() inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sql];
    }];
}

#pragma mark - 更新数据

/**
 *  @author 智奎宇, 16-09-28 20:09:28
 *
 *  modle 数据更新
 */
- (void)update{
    [self updateParam:nil];
}

/**
 *  @author 智奎宇, 16-09-28 20:09:41
 *
 *  数据更新
 *
 *  @param param 数据更新条件
 */
- (void)updateParam:(RBDBParamHelper *)param{
    NSString * checkMy = [self getCheckIsMyStr];
    if(checkMy){
        
        
        [DBQueue() inDatabase:^(FMDatabase *db) {
            NSString * sql ;
            NSDictionary * info = [self getUpdateSql:param];
            if(param){
                sql = [NSString stringWithFormat:@"%@ and ",info[@"sql"], checkMy];
            }else{
                sql = [NSString stringWithFormat:@"%@ where %@",info[@"sql"], checkMy];
            }
            [db executeUpdate:sql withParameterDictionary:info[@"values"]];
        }];
    }else{
        NSLog(@"移除数据异常");
    }
}

- (NSString *)getUpdateSql:(RBDBParamHelper *)param{
    NSDictionary * dict = [self toDict];
    
    if([dict count] == 0){
        NSLog(@"data is nil");
        return nil;
    }
    NSArray * keys = [dict allKeys];
    NSMutableString * sql = [NSMutableString new];
    [sql appendFormat:@"UPDATE %@ SET ",[[self class] getTableName]];
    NSMutableArray * pos  =[NSMutableArray new];
    
    NSMutableDictionary * values = [NSMutableDictionary new];
    for(NSString * key in keys){
        NSObject * obj = [dict objectForKey:key];
        if([obj isKindOfClass:[NSNumber class]]){
            [values setObject:obj forKey:key];
            [pos addObject:[NSString stringWithFormat:@"%@ = :%@",key,key]];
        }else{
            if([obj isKindOfClass:[UIImage class]]){
                [values setObject:UIImagePNGRepresentation(obj) forKey:key];
                [pos addObject:[NSString stringWithFormat:@"%@ = :%@",key,key]];
            }else if([obj isKindOfClass:[NSDate class]]){
                [values setObject:@([(NSDate *)obj timeIntervalSince1970]) forKey:key];
                [pos addObject:[NSString stringWithFormat:@"%@ = :%@",key,key]];
            }else{
                [values setObject:obj forKey:key];
                [pos addObject:[NSString stringWithFormat:@"%@ = :%@",key,key]];
                
            }
        }
    }
    [sql appendFormat:@" %@",[pos componentsJoinedByString:@","]];
    NSLog(@"%@",sql);
    
    if(param){
        NSString * where = [param getTerm];
        if(where)
            sql = [NSString stringWithFormat:@"%@ %@",sql,where];
    }
    return @{@"sql":sql , @"values":values};
}


#pragma mark - 查询数据

/**
 *  @author 智奎宇, 16-09-28 20:09:56
 *
 *  查询所有modle 类型的数据
 */
+ (void)selectAll:(void(^)(NSArray *)) dataBlock{
    [self selectParam:nil :dataBlock];
}

/**
 *  @author 智奎宇, 16-09-28 20:09:20
 *
 *  查询所有modle 类型的数据
 *
 *  @param param 查询条件
 */
+ (void)selectParam:(RBDBParamHelper *)param :(void(^)(NSArray *)) dataBlock{
    if(dataBlock == nil)
        return;
    
    NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ ",[[self class] getTableName]];
    if(param){
        NSString * where = [param getTerm];
        if(where)
        sql = [NSString stringWithFormat:@"%@ %@",sql,where];
    }
    
    [DBQueue() inDatabase:^(FMDatabase *db) {
        FMResultSet * set = [db executeQuery:sql];
        NSArray * array =  [self parseResultSet:set];
        dataBlock(array);
    }];

}


#pragma mark - 数据解析

+ (NSArray *)parseResultSet:(FMResultSet *)set{
    NSDictionary * dict = [set columnNameToIndexMap];
    NSArray * allColumns = [dict allKeys];
    NSArray * modlePropers = [[self class] getAllProperties];
    NSMutableArray * result = [NSMutableArray new];
    int count = 0;
    while ([set next]){
        
        NSObject * modle = [[[self class]  alloc] init];
        count ++;
        for(NSDictionary * propertyInfo in modlePropers){
            NSString * property = [propertyInfo objectForKey:@"property"];
            NSString * name = [propertyInfo objectForKey:@"name"];

            if([allColumns containsObject:name]){
                
                NSObject * obj = [set objectForColumnName:name];
                if(![obj isKindOfClass:[NSNull class]]){
                    NSObject * value = obj;
                    if([property isEqualToString:@"UIImage"]){
                        obj = [UIImage imageWithData:obj];
                    }else if([property isEqualToString:@"NSDate"]){
                        obj = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)obj floatValue]];
                    }
                    if(obj){
                        [modle setValue:obj forKey:name];
                    }
                }
            }else{
                NSLog(@"sqlite not contant line --> %@",name);
            }
        }
        BOOL is = [[self class] primaryKeyObjVar];
        if(!is){
            int obj = [set intForColumn:[self primary]];
            [modle setPrimaryValue:obj];
        
        }
        
        [result addObject:modle];
    }
    return result;
}


@end
