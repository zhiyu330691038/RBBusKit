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
#import <YYKit/NSArray+YYAdd.h>

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
    [sql appendFormat:@"INSERT OR REPLACE INTO %@ ",tableName];
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
    
    
    [DBQueue() inDatabase:^(FMDatabase *db) {
        
        [[self class] enumerationChild:self Param:param excueBlock:^int(RBDBParamHelper * param, NSDictionary * saveDict,NSObject<RBDBProtocol> * modle) {
            __block NSDictionary * sqlino =  [[modle class] getSql:param ObjInfos:saveDict];
            [db executeUpdate:sqlino[@"sql"] withParameterDictionary:sqlino[@"value"]];
            if(![[self class] primaryKeyObjVar]){
                [modle setPrimaryValue:(int)[db lastInsertRowId]];
            }
            return (int)[db lastInsertRowId];
            
        }];
        
    }];
}



+ (int )enumerationChild:(NSObject *)obj Param:(RBDBParamHelper *)param excueBlock:(int (^)(RBDBParamHelper *,NSDictionary *,NSObject<RBDBProtocol> *)) block{
    NSMutableDictionary * saveDict = [[NSMutableDictionary alloc] init];
    NSArray * array = [[obj class] getAllPropertiesNamed];
    for(NSString * key in array){
        id value = [obj valueForKey:key];
        if(value == nil)
            continue;
        if([value isKindOfClass:[NSArray class]]){
            NSMutableArray * newArray = [NSMutableArray new];
            NSArray * currentValue = (NSArray *)value;
            for(id a in currentValue){
                if([a conformsToProtocol:@protocol(RBDBProtocol)]){
                    int oldid = [self enumerationChild:a Param:nil excueBlock:block];
                    [a setPrimaryValue:oldid];
                    [newArray addObject:[NSString stringWithFormat:@"db_modle|%@|%@|%d",NSStringFromClass([a class]),[[a class] getTableName],oldid]];
                }
            }
            NSString * json = nil;
            if(newArray.count == currentValue.count && newArray.count > 0){
                json = [newArray jsonStringEncoded];
            }else{
                json = [currentValue jsonStringEncoded];
            }
            [saveDict setValue:json forKey:key];
        }else if([value conformsToProtocol:@protocol(RBDBProtocol)]){
            int oldid = [self enumerationChild:value Param:nil excueBlock:block];
            [value setPrimaryValue:oldid];
            [saveDict setValue:[NSString stringWithFormat:@"db_modle|%@|%@|%d",NSStringFromClass([value class]),[[value class] getTableName],oldid] forKey:key];
        }
    }
    return block(param,saveDict,obj);
    
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
            [obj saveParam:param];
        }
    }];
}


/**
 *  @author 智奎宇, 16-09-28 20:09:39
 *
 *  删除自身modle
 */
- (void)remove{
    [DBQueue() inDatabase:^(FMDatabase *db) {
        [NSObject enumerationChild:self Param:nil excueBlock:^int(RBDBParamHelper * param, NSDictionary * saveDict,NSObject<RBDBProtocol> * modle) {
            NSString * checkMy = [modle getCheckIsMyStr];
            NSString * sql = [NSString stringWithFormat:@"DELETE FROM %@ where %@",[[modle class] getTableName], checkMy];
            __block NSDictionary * sqlino =  [[modle class] getSql:param ObjInfos:saveDict];
            [db executeUpdate:sql];
            return -1;
        }];
    }];
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
- (void)updateParam:(RBDBParamHelper *)parama{
    [DBQueue() inDatabase:^(FMDatabase *db) {
        [NSObject enumerationChild:self Param:parama excueBlock:^int(RBDBParamHelper * param, NSDictionary * saveDict,NSObject<RBDBProtocol> * modle) {
            NSString * checkMy = [modle getCheckIsMyStr];
            
            
            NSString * sql ;
            NSDictionary * info = [modle getUpdateSql:param ObjInfos:saveDict];
            if(param){
                sql = [NSString stringWithFormat:@"%@ and ",info[@"sql"], checkMy];
            }else{
                sql = [NSString stringWithFormat:@"%@ where %@",info[@"sql"], checkMy];
            }
            [db executeUpdate:sql withParameterDictionary:info[@"values"]];
            return modle.primaryValue;
        }];
        
        
    }];
}

- (NSDictionary *)getUpdateSql:(RBDBParamHelper *)param ObjInfos:(NSDictionary *)dict{
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
            sql = (NSString *)[NSString stringWithFormat:@"%@ %@",sql,where];
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
    
    
    
    [DBQueue() inDatabase:^(FMDatabase *db) {
        [self getResultData:db param:param IsDone:YES excueBlock:^(NSArray * array) {
            if(dataBlock){
                dataBlock(array);
            }
        }];
        
    }];
    
}


+ (NSObject  *)dbStringToObj:(NSString *)dbString{
    if (dbString != nil && ![dbString isKindOfClass:[NSNull class]]) {
        NSError *error = nil;
        NSData * data = [dbString dataUsingEncoding:NSUTF8StringEncoding];
        id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        return  obj ;
    }
    return nil;
}

#pragma mark - 数据解析

+ (NSArray *)getResultData:(FMDatabase *)db param:(RBDBParamHelper *)param IsDone:(BOOL)isDone excueBlock:(void (^)(NSArray *)) block{
    
    NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ ",[[self class] getTableName]];
    if(param){
        NSString * where = [param getTerm];
        if(where)
            sql = [NSString stringWithFormat:@"%@ %@",sql,where];
    }
    FMResultSet * set = [db executeQuery:sql];
    NSArray * array =  [self dbsetToArray:set];
    
    NSArray * modlePropers = [[self class] getAllProperties];
    
    
    NSMutableArray * comArray = [NSMutableArray new];
    
    
    for(NSDictionary * result in array){
        NSMutableDictionary * aaaa = [NSMutableDictionary new];
        for(NSDictionary * propertyInfo in modlePropers){
            NSString * property = [propertyInfo objectForKey:@"property"];
            NSString * name = [propertyInfo objectForKey:@"name"];
            Class class = NSClassFromString(property);
            
            NSObject * value = result[name];
            
            if([class isSubclassOfClass:[NSArray class]]){
                NSObject * dbtype = [self dbStringToObj:(NSString *)value];
                if(dbtype == nil){
                    [aaaa setObject:value forKey:name];
                    continue;
                }
                if([dbtype isKindOfClass:[NSArray class]]){
                    for(NSString * str in dbtype){
                        if([str isKindOfClass:[NSString class]] && [(NSString *)str containsString:@"db_modle|"]){
                            NSArray * dbInfo = [(NSString *)str componentsSeparatedByString:@"|"];
                            Class modleClass = NSClassFromString([dbInfo objectAtIndex:1]);
                            RBDBParamHelper * helper = [[RBDBParamHelper alloc] initModleClass:modleClass];
                            helper.comple([modleClass primary]).equal([dbInfo objectAtIndex:3]);
                            NSArray * cArray = [modleClass getResultData:db param:nil IsDone:NO excueBlock:block];
                            [aaaa setObject:cArray forKey:name];
                        }
                    }
                }
                
            }else if([class conformsToProtocol:@protocol(RBDBProtocol)]){
                NSArray * dbInfo = [(NSString *)value componentsSeparatedByString:@"|"];
                Class modleClass = NSClassFromString([dbInfo objectAtIndex:1]);
                RBDBParamHelper * helper = [[RBDBParamHelper alloc] initModleClass:modleClass];
                helper.comple([modleClass primary]).equal([dbInfo objectAtIndex:3]);
                NSArray * array = [modleClass getResultData:db param:nil IsDone:NO excueBlock:block];
                if(array.count > 0){
                    [aaaa setObject:[array objectAtIndex:0] forKey:name];
                }
            }else{
                NSObject * res = result[name];
                if(res == nil || [res isKindOfClass:[NSNull class]])
                    continue;
                [aaaa setObject:result[name] forKey:name];
            }
        }
        
        NSObject * searchModle = [[self class] modelWithDictionary:aaaa];
        [searchModle setPrimaryValue:[[result objectForKey:[self primary]] intValue]];
        
        [comArray addObject:searchModle];
        
    }
    
    if(block && isDone){
        block(comArray);
    }
    return comArray;
}


+ (NSArray *)dbsetToArray:(FMResultSet *)set{
    NSMutableArray * array = [NSMutableArray new];
    while ([set next]){
        [array addObject:[set resultDictionary]];
    }
    return array;
}

+ (NSArray *)parseResultSet:(FMResultSet *)set{
    NSDictionary * dict = [set columnNameToIndexMap];
    NSArray * allColumns = [dict allKeys];
    NSArray * modlePropers = [[self class] getAllProperties];
    NSMutableArray * result = [NSMutableArray new];
    int count = 0;
    while ([set next]){
        
        NSMutableDictionary * result = [[NSMutableDictionary alloc] initWithDictionary:[set resultDictionary]];
        for(NSDictionary * propertyInfo in modlePropers){
            NSString * property = [propertyInfo objectForKey:@"property"];
            NSString * name = [propertyInfo objectForKey:@"name"];
            Class class = NSClassFromString(property);
            
            if([class isSubclassOfClass:[NSArray class]] || [class isSubclassOfClass:[UIImage class]] ||[class conformsToProtocol:@protocol(RBDBProtocol)]){
                [self dbStringToObj:result[name]];
            }
            
            
        }
        
        
        
        NSObject * modle = [[[self class]  alloc] init];
        count ++;
        for(NSDictionary * propertyInfo in modlePropers){
            NSString * property = [propertyInfo objectForKey:@"property"];
            NSString * name = [propertyInfo objectForKey:@"name"];
            
            if([allColumns containsObject:name]){
                
                
                
                NSObject * obj = [set objectForColumnName:name];
                if(![obj isKindOfClass:[NSNull class]]){

                    if([property isEqualToString:@"UIImage"]){
                        obj = (NSObject *)[UIImage imageWithData:obj];
                    }else if([property isEqualToString:@"NSDate"]){
                        obj = (NSDate *)[NSDate dateWithTimeIntervalSince1970:[(NSNumber *)obj floatValue]];
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
        
    }
    return result;
}


@end
