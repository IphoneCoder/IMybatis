//
//  MappedStatement.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-18.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum
{
    MapperTypeSelect =0,//select
    MapperTypeUpdate = 1,//Update
    MapperTypeInsert = 2,//Insert
    MapperTypeDelete = 3,//Delete
    MapperTypeReplace = 4,//Replace
    MapperTypeResultMap=5//这个不能执行
    
}MapperType;
@interface MappedStatement : NSObject
@property(nonatomic,strong)NSString *mapperNamespace;//mapper namespace
@property MapperType mapperType;//mappertype
@property(nonatomic,strong)NSString *mapperID;//ID
@property(nonatomic,strong)NSString *mapperParameterType;//parameterType
@property(nonatomic,strong)NSString *mapperResultType;//parameterType
@property(nonatomic,strong)NSString *mapperSqlSource;//原始的具体的sql语句
@property(nonatomic,strong)NSString *mapperDisposedSqlSource;//处理后的的具体的sql语句，已经为可执行的sql语句
@property(nonatomic,strong)NSMutableDictionary *mapperOriAttributeDataDic;//得到的原始attribute
@property(nonatomic,strong)NSString *mapperResultMap;//resultMap
@end