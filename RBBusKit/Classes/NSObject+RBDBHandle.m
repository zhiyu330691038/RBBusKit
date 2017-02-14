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
#import <YYKit/NSDictionary+YYAdd.h>
#import "RBDBProtocol.h"
#import "NSObject+YYAdd.h"
#import "NSObject+YYModel.h"

@implementation NSObject (RBDBHandle)
@dynamic primaryValue;
@dynamic superPrimaryValue;

#pragma mark - 获取数据库实例

FMDatabaseQueue * DBQueue(){
    static FMDatabaseQueue * dataQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *Paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path=[Paths objectAtIndex:0];
        NSString * dbPath = [path stringByAppendingString:@"/userinfo.sqlite"];
        NSLog(@"%@",dbPath);
        
        dataQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    });
    return dataQueue;
}

#pragma mark -  set get method

- (int)superPrimaryValue{
    return [objc_getAssociatedObject(self, @"superPrikey") intValue];
}

- (void)setSuperPrimaryValue:(int)superPrimaryValue{
    objc_setAssociatedObject(self, @"superPrikey", @(superPrimaryValue), OBJC_ASSOCIATION_COPY);
}

- (void)setPrimaryValue:(int)primaryValue{
    objc_setAssociatedObject(self, @"prikey", @(primaryValue), OBJC_ASSOCIATION_COPY);
}

- (int)primaryValue{
    return [objc_getAssociatedObject(self, @"prikey") intValue];
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

+ (NSDictionary *)getSql:(RBDBParamHelper *)param ObjInfos:(NSDictionary *)dict superId:(int)superid{
    __block NSString * tableName = [[self class] getTableName];
    if([dict count] == 0){
        NSLog(@"data is nil");
        return nil;
    }
    NSMutableDictionary * modleInfo = [[NSMutableDictionary alloc] initWithDictionary:dict];
    if(superid > 0){
        [modleInfo setObject:@(superid) forKey:@"superid"];
    }
    
    
    NSArray * keys = [modleInfo allKeys];
    NSMutableString * sql = [NSMutableString new];
    [sql appendFormat:@"INSERT OR REPLACE INTO %@ ",tableName];
    [sql appendFormat:@"(%@) ",[keys componentsJoinedByString:@","]];
    NSMutableArray * pos  =[NSMutableArray new];
    
    NSMutableDictionary * values = [NSMutableDictionary new];
    for(NSString * key in keys){
        NSObject * obj = [modleInfo objectForKey:key];
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
        [[self class] enumerationModle:self Param:param excueBlock:^int *(NSString * sql, NSDictionary * values) {
            [db executeUpdate:sql withParameterDictionary:values];
            return [db lastInsertRowId];
        }];
    }];
}

+ (void)enumerationModle:(NSObject *)obj Param:(RBDBParamHelper *)param excueBlock:(int * (^)(NSString *,NSDictionary *)) block{
    NSMutableDictionary * saveDict = [[NSMutableDictionary alloc] initWithDictionary:[obj modelToJSONObject]];
    NSMutableArray * child = [NSMutableArray new];
    [obj filterInfo:&saveDict ChildList:&child];

    for(NSString * key in [saveDict allKeys]){
        id value = [obj valueForKey:key];
        if(value == nil)
            continue;
        if([value isKindOfClass:[NSArray class]]){
            NSString *json = [(NSArray *)value jsonStringEncoded];
            if(json)
                [saveDict setValue:json forKey:key];
        }else if([value isKindOfClass:[NSDictionary class]]){
            NSString *json = [(NSDictionary *)value jsonStringEncoded];
            if(json)
                [saveDict setValue:json forKey:key];
        }
    }
    __block NSDictionary * sqlino =  [[obj class] getSql:param ObjInfos:saveDict superId:obj.superPrimaryValue];
    if(block){
        int private = block(sqlino[@"sql"],sqlino[@"value"]);
        if(obj.primaryValue <= 0){
            obj.primaryValue = private;
        }
    }
    NSMutableArray * modleType = [NSMutableArray new];
    NSString * className = nil;

    NSMutableDictionary * dict = [NSMutableDictionary new];
    
    for(NSObject * object in child){
        [object setSuperPrimaryValue:[obj primaryValue]];
        RBDBParamHelper * helper = [[RBDBParamHelper alloc] initModleClass:[object class]];
        helper.comple(@"superid").equal(@(object.primaryValue));
        [[self class] enumerationModle:object Param:nil excueBlock:block];
        if(![[[object class] className] isEqualToString:className]){
            className = [[object class] className];
            if(![modleType containsObject:className])
            [modleType addObject:className];
        }
        NSMutableArray * privatek = [[NSMutableArray alloc] initWithArray:[dict objectForKey:className]];
        [privatek addObject:@(object.primaryValue)];
        [dict setObject:privatek forKey:className];
    }
}


- (void)filterInfo:(NSMutableDictionary **)info ChildList:(NSMutableArray **)childArray{
    NSMutableDictionary * fileterInfo = *info;
    NSDictionary * modleInfo = nil;
    NSMutableArray * child = *childArray;
    if([[self class] respondsToSelector:@selector(equivalentModle)]){
        modleInfo = [[self class] equivalentModle];
        for(NSString * key in [modleInfo allKeys]){
            [fileterInfo removeObjectForKey:key];
            id value = [self valueForKey:key];
            if([value conformsToProtocol:@protocol(RBDBProtocol)]){
                [child addObject:value];
            }else if([value isKindOfClass:[NSArray class]]){
                for(NSObject * a in value){
                    if([a conformsToProtocol:@protocol(RBDBProtocol)]){
                        [child addObject:a];
                    }
                }
            }else if(value == nil){
            
            }
        }
    }
}



/**
 *  @author 智奎宇, 16-09-28 20:09:09
 *
 *  批量保存数据
 *
 *  @param array modle 数组
 *  @param param 保存的条件
 */
+ (void)saveArrays:(NSArray <id<RBDBProtocol>> *) array{
    for(NSObject * obj in array){
        [obj save];
    }
}

#pragma mark -

/**
 *  @author 智奎宇, 16-09-28 20:09:39
 *
 *  删除自身modle
 */
- (void)remove{
    [DBQueue() inDatabase:^(FMDatabase *db) {
        [NSObject enumerationDeleteModle:self SuperId:0 excueBlock:^void(NSString * sql, NSDictionary * values) {
            [db executeUpdate:sql withParameterDictionary:values];
        }];
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
    [DBQueue() inDatabase:^(FMDatabase *db) {
        
    }];

}


+ (void)enumerationDeleteModle:(NSObject *)obj SuperId:(int)superId excueBlock:(void (^)(NSString *,NSDictionary *)) block{
    __block NSString * tableName = [[obj  class] getTableName];
    NSString * string ;
    if(obj.primaryValue > 0 && superId > 0){
        string = [NSString stringWithFormat:@"DELETE FROM %@ WHERE  id = %d and superid=%d",tableName,obj.primaryValue,superId];
    }else if(superId > 0){
        string = [NSString stringWithFormat:@"DELETE FROM %@ WHERE  superid=%d",tableName,superId];
    }else if(obj.primaryValue > 0){
        string = [NSString stringWithFormat:@"DELETE FROM %@ WHERE  id = %d",tableName,obj.primaryValue];
    }else{
        return;
    }
    if(block){
        block(string,nil);
    }
    
    if([[obj class] respondsToSelector:@selector(equivalentModle)]){
        NSDictionary *  modleInfo = [[obj class] equivalentModle];
        
        NSMutableArray *  modleKeys = [[NSMutableArray alloc] initWithArray:[modleInfo allKeys]];
        for(NSString * key in modleKeys){
            NSObject * value = [obj valueForKey:key];
            if([value isKindOfClass:[NSArray class]]){
                for(NSObject * child in value){
                    if(child && [child conformsToProtocol:@protocol(RBDBProtocol)]){
                        [NSObject enumerationDeleteModle:child  SuperId:obj.primaryValue excueBlock:block];
                    }
                }
            }else if(value && [modleKeys conformsToProtocol:@protocol(RBDBProtocol)]){
                [NSObject enumerationDeleteModle:value  SuperId:obj.primaryValue excueBlock:block];
            }
        }
    }
}

+ (NSArray *)getCleanRedundancySql:(NSDictionary *)dict superID:(int)superId{
    NSMutableArray * sqlStringArray = [NSMutableArray new];
    
    for(NSString * key in [dict allKeys] ){
        __block NSString * tableName = [NSClassFromString(key) getTableName];
        NSMutableArray * values = [[NSMutableArray alloc] initWithArray:[dict objectForKey:key]];
        if(values.count == 0)
            continue;
        for(int i = 0 ; i < values.count ; i++){
            [values replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@" id <> %@ ",[values objectAtIndex:i]]];
        }
        NSMutableString * string = [NSString stringWithFormat:@"DELETE FROM %@ WHERE (%@) and superid = %d",tableName,[values componentsJoinedByString:@"and"],superId];
        [sqlStringArray addObject:string];
    }
    
    if([[self class] respondsToSelector:@selector(equivalentModle)]){
        NSDictionary *  modleInfo = [[self class] equivalentModle];
        
        NSMutableArray *  modleValues = [[NSMutableArray alloc] initWithArray:[modleInfo allValues]];
        [modleValues removeObjectsInArray:[dict allKeys]];
        for(NSString * valus in modleValues){
            __block NSString * tableName = [NSClassFromString(valus) getTableName];
            
            NSMutableString * string = [NSString stringWithFormat:@"DELETE FROM %@ WHERE  superid = %d",tableName,superId];
            [sqlStringArray addObject:string];
            
        }
        
    }
    return sqlStringArray;
}

/**
 *  @author 智奎宇, 16-09-28 20:09:49
 *
 *  删除所有modle 类型数据
 */
+ (void)cleanDB{
    [self removeParam:nil];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                if(dataBlock){
                    dataBlock(array);
                }
            });
           
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

            NSObject * res = result[name];
            if(res == nil || [res isKindOfClass:[NSNull class]])
                continue;
            [aaaa setObject:result[name] forKey:name];
        }
        NSObject * searchModle = [[self class] modelWithDictionary:aaaa];
        [searchModle setPrimaryValue:[[result objectForKey:@"id"] intValue]];
        id superid = [result objectForKey:@"superid"];
        if(superid != nil && ![superid isKindOfClass:[NSNull class]])
            [searchModle setSuperPrimaryValue:[superid intValue]];
        [comArray addObject:searchModle];
        
        if([[searchModle class] respondsToSelector:@selector(equivalentModle)]){
            NSDictionary *  modles = [[searchModle class] equivalentModle] ;
            
            for(NSString * key in [modles allKeys]){
                Class class = NSClassFromString([modles objectForKey:key]);
                RBDBParamHelper * helper = [[RBDBParamHelper alloc] initModleClass:class];
                helper.comple(@"superid").equal(@(searchModle.primaryValue));
                NSArray * res = [class getResultData:db param:helper IsDone:NO excueBlock:nil];
                
                if([[searchModle class] propertyIsArray:modlePropers Key:key]){
                    [searchModle setValue:res forKey:key];
                }else{
                    if(result.count > 0){
                        [searchModle setValue:[res firstObject] forKey:key];
                    }
                }
            }
        }
    }
    
    if(block && isDone){
        block(comArray);
    }
    return comArray;
}


+ (bool)propertyIsArray:(NSArray *)allProper Key:(NSString *)key{
    for(NSDictionary * propertyInfo in allProper){
        NSString * property = [propertyInfo objectForKey:@"property"];
        NSString * name = [propertyInfo objectForKey:@"name"];
        if([name isEqualToString:key]){
            if([property isEqualToString:@"NSArray"]){
                return YES;
            }
        }
    }
    return NO;

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
        
        
//        NSString * obj = [set stringForColumn:[self primary]];
//        [modle setPrimaryValue:obj];
        
        
    }
    return result;
}



#pragma mark - 数据copy 情况

+ (void)changeCopyMethod{
    SEL oriSEL = @selector(copyWithZone:);
    SEL cusSEL = @selector(rb_copyWithZone:);
    
    [self changeMethod:oriSEL toMethod:cusSEL];
    
    SEL oriSEL1 = @selector(encodeWithCoder:);
    SEL cusSEL1 = @selector(rb_encodeWithCoder:);
    
    [self changeMethod:oriSEL1 toMethod:cusSEL1];
    
    
    SEL oriSEL2 = @selector(initWithCoder:);
    SEL cusSEL2 = @selector(rb_initWithCoder:);
    
    [self changeMethod:oriSEL2 toMethod:cusSEL2];
}


+ (void)changeMethod:(SEL) oriSEL toMethod:(SEL) cusSEL{
    
    Class selfClass = [self class];
    Method oriMethod = class_getInstanceMethod(selfClass, oriSEL);
    
    Method cusMethod = class_getInstanceMethod(selfClass, cusSEL);
    
    BOOL addSucc = class_addMethod(selfClass, oriSEL, method_getImplementation(cusMethod), method_getTypeEncoding(cusMethod));
    if (addSucc) {
        class_replaceMethod(selfClass, cusSEL, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    }else {
        method_exchangeImplementations(oriMethod, cusMethod);
    }
    
}


//归档
- (void)rb_encodeWithCoder:(NSCoder *)aCoder {
    if([self conformsToProtocol:@protocol(RBDBProtocol)]){
        [self modelEncodeWithCoder:aCoder];
        [aCoder encodeObject:@(self.primaryValue) forKey:@"prikey"] ;
    }else{
        [self rb_encodeWithCoder:aCoder];
    }
}
//解档
- (id)rb_initWithCoder:(NSCoder *)aDecoder{
    if([self conformsToProtocol:@protocol(RBDBProtocol)]){
        NSObject * obj = [self modelInitWithCoder:aDecoder];
        [obj setPrimaryValue:[aDecoder decodeObjectForKey:@"prikey"]];
        return obj;
    }else{
        return [self rb_initWithCoder:aDecoder];
    }
}

- (id)rb_copyWithZone:(NSZone *)zone{
    if([self conformsToProtocol:@protocol(RBDBProtocol)]){
//        NSObject * object = [self modelCopy];
//        if([object conformsToProtocol:@protocol(RBDBProtocol)]){
//            [object setPrimaryValue:[self primaryValue]];
//        }
//        return object;
        return [self modelCopy];
    }else{
        return [self rb_copyWithZone:zone];
    }
   
}

@end
