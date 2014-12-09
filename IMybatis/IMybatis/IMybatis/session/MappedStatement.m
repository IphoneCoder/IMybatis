//
//  MappedStatement.m
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-18.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import "MappedStatement.h"

@implementation MappedStatement
@synthesize  mapperNamespace;//mapper namespace
@synthesize  mapperType;//mappertype
@synthesize  mapperID;//ID
@synthesize  mapperParameterType;//parameterType
@synthesize  mapperResultType;//parameterType
@synthesize  mapperSqlSource;//原始的具体的sql语句
@synthesize  mapperDisposedSqlSource;//处理后的的具体的sql语句，已经为可执行的sql语句
@synthesize mapperOriAttributeDataDic;
@synthesize mapperResultMap;

@end
