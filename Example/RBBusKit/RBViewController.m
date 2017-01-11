//
//  RBViewController.m
//  RBBusKit
//
//  Created by zhikuiyu on 09/24/2016.
//  Copyright (c) 2016 zhikuiyu. All rights reserved.
//

#import "RBViewController.h"
#import "RB1.h"
#import "RBtewtetw.h"
#import "RBDBParamHelper.h"
#define onExit\
__strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^

@interface RBViewController ()

@end
__attribute__((overloadable))

void logAnything(id obj) {
    
    NSLog(@"%@", obj);
    
}

__attribute__((overloadable)) void logAnything(int number) {
    
    NSLog(@"%@", @(number));
    
}

__attribute__((overloadable)) void logAnything(CGRect rect) {
    
    NSLog(@"%@", NSStringFromCGRect(rect));
    
}

#define NS_REQUIRES_SUPER __attribute__((objc_requires_super))
@implementation RBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
  
    RB1 * rb = [[RB1 alloc] init];
    rb.aaa =  1000;
    
    rb.i = 123 ;
    RBtewtetw * aaa = [[RBtewtetw alloc] init];
    aaa.aaaa = 1321;
    aaa.aaa = 1000;
    
    
    RBTest1 * test = [[RBTest1 alloc] init];
    test.name = @"1";
    
    RBTest1 * test2 = [[RBTest1 alloc] init];
    test2.name = @"1";
    aaa.arr1 = @[test,test2];
    
    RBtewtetw * aaa1 = [[RBtewtetw alloc] init];
    aaa1.aaaa = 1321;
    aaa1.aaa = 1000;
    rb.arr = @[aaa,aaa1];
    
    
    RB1 * aa = [rb copy];
    NSArray * arra = @[[rb copy],[rb copy],[rb copy]];
    

//    [rb save];
    

    

    [RB1 selectAll:^(NSArray * array) {
        NSLog(@"%@",array);
        for(RB1 * obj in array){
            [obj remove];
        }
    }];
    ///* 保存数据

    return;
    NSMutableArray * array = [NSMutableArray new];
    
    for(int i = 0 ; i < 100; i ++){
        RB1 * rb = [[RB1 alloc] init];
        rb.aaa = i + 1000;

        rb.i = i ;
        RBtewtetw * aaa = [[RBtewtetw alloc] init];
        aaa.aaaa = 3433;
        rb.arr = @[aaa];
        aaa.aaa = rand() % 1000;
        rb.f = i * i;
        
        [array addObject:rb];
        [rb save];
    }
    
    
    
    [RB1 saveArrays:array];
    
//    for(int i = 10 ; i < 20; i ++){
//        RB1 * rb = [array objectAtIndex:i];
//        NSArray * aa = rb.arr;
//        ((RBtewtetw *)[aa objectAtIndex:0]).aaaa = 3234;
//        [rb copy];
//        [[rb copy] update];
//    }
    
    
     //*/

    
    /* 条件查询数据
    RB1 * rb1 = [[RB1 alloc] init];

    RBDBParamHelper * helper = [[RBDBParamHelper alloc] initModleClass:[RB1 class]];
    helper.comple(HKey(rb1.aaa)).lessThan(@(1100))
    .AND().comple(HKey(rb1.aaaa)).greaterThan(@(8400))
    .AND().comple(HKey(rb1.teaa)).prefix(@"teaa  1");
    
    helper.sort(HKey(rb1.aaaa),DESC);
    
    helper.count(5);
    
    
    [RB1 selectParam:helper :^(NSArray * array) {
        
        NSLog(@"%@",array);
    }];
    */
    
    
    
    ///* 全部查询
//    [RB1 selectAll:^(NSArray * array) {
//        NSLog(@"%@",array);
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            RB1 * rb = [array objectAtIndex:0];
//            rb.aaa = 0 ;
//            rb.aba = @(3);
//            rb.taa = @"111111111111111";
//            [rb update];
//        });
//    }];
     //*/
    

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
