//
//  NSObject+RBModle.m
//  Pods
//
//  Created by Zhi Kuiyu on 16/10/13.
//
//

#import "NSObject+RBModle.h"
#import <objc/runtime.h>

@implementation NSObject (RBModle)

- (void)updateFromModle:(NSObject *)modle{
    if(![[[modle class] description] isEqualToString:[[self class] description]]){
        NSLog(@"只能是同类型的modle");
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class clazz = [self class];
    u_int count;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    for (int i = 0; i < count ; i++)
    {
        objc_property_t prop=properties[i];
        const char* propertyName = property_getName(prop);
        id newValue = [modle performSelector:NSSelectorFromString([NSString stringWithUTF8String:propertyName])];
        NSString * pro = [NSString stringWithUTF8String:propertyName];
        pro = [pro stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[pro substringToIndex:1] uppercaseString]];
        NSString *destMethodName = [NSString stringWithFormat:@"set%@:",pro];
        SEL destMethodSelector = NSSelectorFromString(destMethodName);
        if(newValue != nil){
            if ([self respondsToSelector:destMethodSelector]) {
                [self performSelector:destMethodSelector withObject:newValue];
            }
        }
    }
    free(properties);
#pragma clang diagnostic pop
}

@end
