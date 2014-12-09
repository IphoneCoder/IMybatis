//
//  MyBatisUtilies.m
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-25.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import "MyBatisUtilies.h"
#import <objc/runtime.h>

@implementation MyBatisUtilies
+(NSArray *)getAllPropertysWithClassName:(NSString *)objectName
{
    NSMutableArray *mutArray=[NSMutableArray arrayWithCapacity:0];
    unsigned int _outCount ;
    const char *_className_C = [objectName UTF8String];
    id propertyCustomer = objc_getClass(_className_C);
    
    objc_property_t *const _properties = class_copyPropertyList(propertyCustomer, &_outCount);
    objc_property_t * _pProperty = _properties;
    for (NSInteger _i = _outCount -1; _i >= 0; _i--, _pProperty++) {
        NSString *_getPropertyName = [NSString stringWithCString:property_getName(*_pProperty) encoding:NSUTF8StringEncoding];
        [mutArray addObject:_getPropertyName];
       
    }
    return [NSArray arrayWithArray:mutArray];
}
+(NSMutableDictionary *)getPropertyClassTypeAndName:(NSString *)objectName
{
    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
//    Class class=NSClassFromString(@"UserBean");
//    id obj=[[class alloc]init];
//    [obj setValue:@"D444444SD酸" forKey:@"userId"];
   // [obj setFloat:0.0 forKey:@"pace"];
    unsigned int numIvars = 0;
    const char *_className_C = [objectName UTF8String];
    Ivar * ivars = class_copyIvarList(objc_getClass(_className_C), &numIvars);
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = ivars[i];
        NSString *type=[NSString stringWithCString:ivar_getTypeEncoding(thisIvar) encoding:NSUTF8StringEncoding];
        NSString *name=[NSString stringWithCString:ivar_getName(thisIvar) encoding:NSUTF8StringEncoding];
        if (type.length>0&&name.length>0) {
            [mutDic setObject:type forKey:name];
        }
    }
    free(ivars);
    return mutDic;
}
@end
