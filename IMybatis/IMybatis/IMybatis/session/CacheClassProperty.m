//
//  CacheClassProperty.m
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-12-8.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import "CacheClassProperty.h"

@implementation CacheClassProperty
@synthesize classImpDic;
@synthesize numberFormatter;
+ (instancetype)sharedInstance
{
    static CacheClassProperty *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
        instance.numberFormatter=[[NSNumberFormatter alloc]init];
    });
    return instance;
}

@end
