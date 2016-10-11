//
//  NSObject+Helper.m
//  Pods
//
//  Created by Zhi Kuiyu on 16/10/11.
//
//

#import "NSObject+Helper.h"
#import "NSObject+RBTools.h"
#import "RBDBProtocol.h"

@implementation NSObject (Helper)




/**
 *  @author 智奎宇, 16-09-26 16:09:55
 *
 *  转化成字典
 *
 *  @return 字典 数据
 */
- (NSDictionary *)toDict{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary] ;

    for (NSDictionary * propertyName in [[self class] getAllPropertiesNamed])
    {
        SEL seleter = NSSelectorFromString(propertyName);
        id value = [self valueForKey:propertyName];
        if(value != nil){
            id resultValue = nil;
            
            if([value isKindOfClass:[NSArray class]]){
                NSMutableArray * array = [NSMutableArray new];
                for(NSObject<RBDBProtocol> * modle in value){
                    [array addObject:[modle toDict]];
                }
                resultValue = [array copy];
            }else if([value conformsToProtocol:@protocol(RBDBProtocol)]){
                resultValue = [value toDict];
            }else{
                resultValue = value;
            }
            [dict setObject:resultValue forKey:propertyName];
        }
    }
    
    return dict;

}
/**
 *  @author 智奎宇, 16-09-26 16:09:55
 *
 *  转化成json 数据
 *
 *  @return json 数据
 */
- (NSString *)toJSONString{
    NSDictionary * dict = [self toDict];
    
    if([NSJSONSerialization isValidJSONObject:dict]){
        NSData  * data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        NSString * jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    return @"";

}


- (NSString *)description{
    
    return [NSString stringWithFormat:@"Modle Class (%@)\n%@",[self class],[[[[self toJSONString] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"	" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
}
@end
