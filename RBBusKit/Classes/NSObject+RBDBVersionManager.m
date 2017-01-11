//
//  NSObject+RBDBVersionManager.m
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/27.
//
//

#import "NSObject+RBDBVersionManager.h"
#import "NSObject+RBDBHandle.h"
#import "RBDBProtocol.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import "NSObject+RBTools.h"
#import "RBDBProtocol.h"

NSComparator cmptr = ^(id obj1, id obj2){
    if ([obj1 hash] > [obj2 hash]) {
        return (NSComparisonResult)NSOrderedDescending;
    }
    
    if ([obj1 hash] < [obj2 hash]) {
        return (NSComparisonResult)NSOrderedAscending;
    }
    return (NSComparisonResult)NSOrderedSame;
};


@implementation NSObject (RBDBVersionManager)
+ (void)load{
    [[NSObject class] performSelector:@selector(changeCopyMethod)];

    Class * classes = NULL;
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0 )
    {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; ++i){
            if ([class_getSuperclass(classes[i]) isSubclassOfClass:[NSObject class]] ){
                if([classes[i] conformsToProtocol:@protocol(RBDBProtocol)]){
                    @autoreleasepool {
                        [classes[i] loadDBVersion];

                    }
                }
            }
        }
        free(classes);
    }
    
    [self cleanTable];
    
    
}

+ (void)cleanTable{
    NSMutableDictionary * dbInfo = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"RBDbInfo"]];

    BOOL isChange = NO;
    for(NSString * keys in [dbInfo allKeys]){
        if([keys isEqualToString:@"dbVersion"]){
            continue;
        }
        
       Class class =  NSClassFromString(keys);
        if(![class conformsToProtocol:@protocol(RBDBProtocol)]){
            @autoreleasepool {
                isChange = YES;
                [class deleteTable];
                [dbInfo removeObjectForKey:keys];
            }
        }
    }
    if(isChange){
        [[NSUserDefaults standardUserDefaults] setObject:dbInfo forKey:@"RBDbInfo"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }


}

/**
 *  @author 智奎宇, 16-09-27 19:09:39
 *
 *  数据库版本维护
 *
 */
+ (void)loadDBVersion{
    
    NSArray * array = [self getAllPropertiesNamed];
    
    NSArray *sortArray = [array sortedArrayUsingComparator:cmptr];
    NSString *currenInfo = [sortArray componentsJoinedByString:@","];
    NSString * keyStr = [[self class] description];
    
    NSDictionary * dbInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"RBDbInfo"];
    NSDictionary * tableInfo = [dbInfo objectForKey:keyStr];
    
    NSUInteger version = [[tableInfo objectForKey:@"versioin"] intValue] ;
    NSString * tableKey = [tableInfo objectForKey:@"keys"];
    NSArray * uniques = [tableInfo objectForKey:@"unique"];
    
    NSArray * currentQunques = nil;
    
    if([[self class] respondsToSelector:@selector(uniqueKeys)]) {
        currentQunques = [[self class] uniqueKeys];
    
    }
    if([tableKey isEqualToString:currenInfo] && ((currentQunques == nil && uniques ==nil) || ([currentQunques isEqualToArray:uniques]))){
        NSLog(@"%@ The latest version",self);
        return ;
    }
    version ++;
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithDictionary:dbInfo];
    if([currenInfo length] == 0){
        [dict removeObjectForKey:keyStr];
        [self deleteTable];
    }else {
        if(currentQunques != nil){
            [dict setObject:@{@"versioin":@(version),@"keys":currenInfo,@"unique":currentQunques} forKey:keyStr];
        }else{
            [dict setObject:@{@"versioin":@(version),@"keys":currenInfo} forKey:keyStr];
        }
        [self changeTable:tableKey];
    }
  
    
    if([dict count] == 0)
        return ;
    
    NSUInteger dbVersion = [[dbInfo objectForKey:@"dbVersion"] intValue];
    dbVersion ++;
    [dict setObject:@(dbVersion) forKey:@"dbVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"RBDbInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


+ (void)changeTable:(NSString *)oldkeystring{
    if([oldkeystring isKindOfClass:[NSString class]] && [oldkeystring length] > 0){
        NSArray * oldkeys = [oldkeystring componentsSeparatedByString:@","];
        [self resetTable:oldkeys];
    }else{
        NSString * sql = [self getCreateTableSql:nil];
        NSLog(@"%@",sql);
        [NSObject executeSQL:sql];
    }
}

+ (void)resetTable:(NSArray *)oldKeys{
    
    NSMutableArray * sqlArray = [NSMutableArray new];
    NSString * tempName = @"temp";
    NSString * tempSql = [self getCreateTableSql:tempName];
    if(tempSql == nil){
        NSString * temp = [NSString stringWithFormat:@"reset table error %@",self];
        NSAssert(tempSql != nil, temp);
        return;
    }
    [sqlArray addObject:[NSString stringWithFormat:@"%@",tempSql]];
    
    NSMutableArray * publicKeys = [NSMutableArray new];
    NSArray * allkeys = [self getAllPropertiesNamed];
    for(NSString * key in allkeys){
        if([oldKeys containsObject:key]){
            [publicKeys addObject:key];
        }
    }
    NSString * tableName = [self getTableName];
    if([publicKeys count] > 0){
        NSString * par = [publicKeys componentsJoinedByString:@","];
        [sqlArray addObject:[NSString stringWithFormat:@"INSERT INTO %@ (%@) SELECT %@ FROM %@",tempName,par,par,tableName]];
    }
    [sqlArray addObject:[NSString stringWithFormat:@"DROP TABLE %@ ",tableName]];
    [sqlArray addObject:[NSString stringWithFormat:@"alter table %@ rename to %@ ",tempName,tableName]];
    NSLog(@"%@",sqlArray);
    [NSObject transaction:^NSArray *{
        return sqlArray;
    }];
}


+ (void)deleteTable{
    NSString * sql = [NSString stringWithFormat:@"drop table %@" , [self getTableName]];
    NSLog(@"%@",sql);
    [NSObject executeSQL:sql];
    
}

+ (NSString *)getCreateTableSql:(NSString *)istemp{
    NSArray * array = [self getAllProperties];
    if(array.count == 0)
        return nil;
    NSMutableString * sql = [NSMutableString new];
    NSMutableArray * paramArray = [NSMutableArray new];
    for(NSDictionary * dict in array){
        NSString * type = [self ocTypeToSql:dict[@"property"]];
        NSString * name = dict[@"name"];
        if([type length] > 0 && [name length] > 0){
            if([[self class] respondsToSelector:@selector(uniqueKeys)] && [[[self class] uniqueKeys] containsObject:name]){
                [paramArray addObject:[NSString stringWithFormat:@"%@ %@ unique",name,type]];
            }else{
                [paramArray addObject:[NSString stringWithFormat:@"%@ %@",name,type]];
            }
        }
    }
    NSString * paramStr = [paramArray componentsJoinedByString:@","];
    if([paramStr length] == 0){
        return nil;
    }
    NSString * crateStr = @"";
    if([istemp length] > 0){
        crateStr = [NSString stringWithFormat:@"CREATE TABLE %@ ",istemp];
    }else{
        crateStr = [NSString stringWithFormat:@"CREATE TABLE %@",[self getTableName]];
    }
    [sql appendFormat:@"%@  ( id integer primary key autoincrement , %@ ,superid integer)",crateStr,paramStr];
    return sql;
}


+ (NSString *)getTableName{
    NSString * name = [[[self class] description] lowercaseString];
    if([name hasPrefix:@"rb"]){
        name = [name stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@"db_"];
    }else{
        name = [NSString stringWithFormat:@"db_%@",name];
    }
    return name;
    
}
@end
