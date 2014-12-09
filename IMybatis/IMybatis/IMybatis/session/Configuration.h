//
//  Configuration.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-17.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MappedStatement.h"
#import "ResultMapStatement.h"
#import "FMDB.h"
@interface Configuration : NSObject
@property(nonatomic,strong)NSString *databasename;
@property(nonatomic,strong)NSString *databasePath;
@property(nonatomic,strong)NSMutableArray *otherInfoArray;//存放其他解析，但是没有用到的数据
@property(nonatomic,strong)NSMutableDictionary *mappedStatementDic;//存放解析后的MappedStatement
@property(nonatomic,strong)NSMutableDictionary *resultMapStatementDic;//存放解析后的ResultMap
@property(nonatomic,strong)FMDatabaseQueue *databaseQueue;
@end
