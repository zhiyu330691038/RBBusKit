# RBBusKit

[![CI Status](http://img.shields.io/travis/zhikuiyu/RBBusKit.svg?style=flat)](https://travis-ci.org/zhikuiyu/RBBusKit)
[![Version](https://img.shields.io/cocoapods/v/RBBusKit.svg?style=flat)](http://cocoapods.org/pods/RBBusKit)
[![License](https://img.shields.io/cocoapods/l/RBBusKit.svg?style=flat)](http://cocoapods.org/pods/RBBusKit)
[![Platform](https://img.shields.io/cocoapods/p/RBBusKit.svg?style=flat)](http://cocoapods.org/pods/RBBusKit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

RBBusKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "RBBusKit"
```

## Author

zhikuiyu, zhikuiyu@roobo.com

## License

RBBusKit is available under the MIT license. See the LICENSE file for more info.



### 保存数据
```
NSMutableArray * array = [NSMutableArray new];

for(int i = 0 ; i < 1000; i ++){
RB1 * rb = [[RB1 alloc] init];
rb.aaa = i + 1000;
rb.aaaa = 10000 - i * i ;
rb.fdas = 100000 - i  ;
rb.teaa = [NSString stringWithFormat:@"teaa  %d",i];
rb.i = i ;
rb.image = [UIImage imageNamed:@"1"];
rb.data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"11" ofType:@"p12"]]];
rb.adta = [NSDate dateWithTimeIntervalSinceNow:i % 100];
rb.f = i * i;
[array addObject:rb];
//        [rb save];
}

[RB1 save:array Param:nil];

for(int i = 0 ; i < 1000; i ++){
RB1 * rb = [array objectAtIndex:i];
NSLog(@"%d",[rb primaryValue]);
}

*/
```

### 条件查询数据
```

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



/* 全部查询
[RB1 selectAll:^(NSArray * array) {
NSLog(@"%@",array);

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

RB1 * rb = [array objectAtIndex:0];
rb.aaa = 0 ;
rb.aba = @(3);
rb.taa = @"111111111111111";
[rb update];
});
}];
*/
```
