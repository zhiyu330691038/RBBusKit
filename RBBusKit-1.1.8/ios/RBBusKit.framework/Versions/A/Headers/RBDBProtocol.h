//
//  RBDBProtocol.h
//  Pods
//
//  Created by Zhi Kuiyu on 16/9/27.
//
//

#import <Foundation/Foundation.h>

#import "NSObject+RBDBHandle.h"
#import <YYKit/NSObject+YYModel.h>
#import "NSObject+RBModle.h"


@protocol RBDBProtocol <NSObject>

@optional
+ (NSString *) primary;


@end
