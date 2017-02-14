//
//  NSObject+RBTools.m
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/27.
//
//

#import "NSObject+RBTools.h"
#import "objc/runtime.h"
#import "RBDBProtocol.h"

#import "NSObject+RBDBVersionManager.h"



@implementation NSObject (RBTools)
/**
 *  @author 智奎宇, 16-09-26 21:09:13
 *
 *  数据库版本号
 *
 */
+ (NSUInteger)dbVersion{
    return [[[[NSUserDefaults standardUserDefaults] objectForKey:@"RBDbInfo"] objectForKey:@"dbVersion"] unsignedIntegerValue];
}

/**
 *  @author 智奎宇, 16-09-26 21:09:09
 *
 *  表的版本号
 *
 *  @return 表版本号
 */
+ (NSUInteger)tbVersion{
    NSString * keyStr = [[self class] description];
    
    return [[[[[NSUserDefaults standardUserDefaults] objectForKey:@"RBDbInfo"] objectForKey:keyStr] objectForKey:@"versioin"] unsignedIntegerValue];
}



#pragma mark 工具获取类信息
+ (NSString *)runToOCType:(NSString *)property{
    NSArray * tempArr = [property componentsSeparatedByString:@","];
    if([tempArr count] < 1)
        return nil;
    NSString * temp = [tempArr firstObject];
    if(![temp isKindOfClass:[NSString class]] || [temp length] == 0)
        return nil;
    NSString * runType = [temp stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    runType = [runType stringByReplacingOccurrencesOfString:@"@" withString:@""];
    runType = [runType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    if([runType length] == 1){
        runType = [runType lowercaseString];
    }
    return runType;
}

+ (NSString *)ocTypeToSql:(NSString *)type{
    if([type isEqualToString:@"i"] || [type isEqualToString:@"b"]){
        return @"INTEGER";
    }else if([type isEqualToString:@"f"] || [type isEqualToString:@"f"] || [type isEqualToString:@"d"]|| [type isEqualToString:@"l"]|| [type isEqualToString:@"NSNumber"]|| [type isEqualToString:@"NSDate"]){
        return @"FLOAT";
    }else if([type isEqualToString:@"NSData"]){
        return @"BLOB";
    }
    return @"TEXT";
}


+ (NSDictionary *)infoWithInstance:(NSString *)instanceName
{
    unsigned int numIvars = 0;
    NSString *key=nil;
    NSString *pro=nil;
    objc_property_t * ivars = class_copyPropertyList([self class], &numIvars);
    for(int i = 0; i < numIvars; i++) {
        objc_property_t thisIvar = ivars[i];
        key = [NSString stringWithUTF8String:property_getName(thisIvar)];
        if([key isEqualToString:instanceName]){
            pro = [NSString stringWithUTF8String:property_getAttributes(thisIvar)]; //获取成员变量的数据类型
            pro = [self runToOCType:pro];
            break;
        }
    }
    free(ivars);
    if([instanceName isEqualToString:@"superid"]){
        return @{@"name":instanceName,@"property":@"i"};
        
    }
    if(key == nil || pro == nil)
        return nil;
   
    
    return @{@"name":key,@"property":pro};
    
}
/**
 *  @author 智奎宇, 16-09-27 21:09:43
 *
 *  获取所有的属性列表
 *
 *  @retu
 */
+ (NSArray *)getAllProperties{
    
    NSMutableArray * array = [NSMutableArray new];
    Class clazz = [self class];
    while ([clazz conformsToProtocol:@protocol(RBDBProtocol)]) {
        u_int count;
        u_int s_count ;
        objc_property_t* properties = class_copyPropertyList(clazz, &count);
        Class superClass = [NSObject class];
        objc_property_t* su_properties = class_copyPropertyList(superClass, &s_count);
        
        for (int i = 0; i < count ; i++)
        {
            objc_property_t prop=properties[i];
            const char* pro = property_getName(prop);
            NSString * propertyName = [NSString stringWithUTF8String:pro];
            const char* propertyType = property_getAttributes(prop);
            NSString * property = [NSString stringWithUTF8String:propertyType];
            //屏蔽nsobject 的属性
            BOOL isObjectPro = NO;
            for(int j = 0 ; j < s_count ; j++){
                objc_property_t superprop=su_properties[j];
                const char* superpropertyName = property_getName(superprop);
                if([propertyName isEqualToString:[NSString stringWithUTF8String:superpropertyName]]){
                    isObjectPro = YES;
                    break;
                }
            }
            if(isObjectPro)
                continue;
            property = [self runToOCType:property];
            if([propertyName length] > 0 && [property length] > 0){
                
                [array addObject:@{@"name":propertyName,@"property":property}];
            }
        }
        free(properties);
        free(su_properties);
        clazz = [clazz superclass];
    }
    return array;
}

+ (NSArray *)getAllPropertiesNamed{
    
    NSMutableArray * array = [NSMutableArray new];
    for(NSDictionary * dic in [self getAllProperties]){
        [array addObject:dic[@"name"]];
    }
    [array addObject:@"superid"];
    return array;
}



@end
