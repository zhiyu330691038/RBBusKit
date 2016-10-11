//
//  NSObject+Helper.h
//  Pods
//
//  Created by Zhi Kuiyu on 16/10/11.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (Helper)


+ (nullable instancetype)modelWithJSON:(id)json;


+ (nullable instancetype)modelWithDictionary:(NSDictionary *)dictionary;


- (BOOL)modelSetWithJSON:(id)json;


- (BOOL)modelSetWithDictionary:(NSDictionary *)dic;


- (nullable id)modelToJSONObject;


- (nullable NSData *)modelToJSONData;


- (nullable NSString *)modelToJSONString;


- (nullable id)modelCopy;


- (void)modelEncodeWithCoder:(NSCoder *)aCoder;


- (id)modelInitWithCoder:(NSCoder *)aDecoder;


- (NSUInteger)modelHash;


- (BOOL)modelIsEqual:(id)model;

- (NSString *)modelDescription;

/**
 *  @author 智奎宇, 16-09-26 16:09:55
 *
 *  转化成字典
 *
 *  @return 字典 数据
 */
- (NSDictionary *)toDict;
/**
 *  @author 智奎宇, 16-09-26 16:09:55
 *
 *  转化成json 数据
 *
 *  @return json 数据
 */
- (NSString *)toJSONString;

@end
