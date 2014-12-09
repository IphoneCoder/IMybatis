//
//  DefaultSqlSession.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-17.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqlSession.h"
#import "Configuration.h"
#import "Executor.h"
@interface DefaultSqlSession : NSObject<SqlSession>
@property(nonatomic,strong)Configuration *configuration;
@property BOOL autoCommit;
@property BOOL transaction;
@property(nonatomic,strong)id<Executor>defaultExecutor;
-(id)initSqlSessionWithConfiguration:(Configuration *)_configuration;
-(id)initSqlSessionWithConfiguration:(Configuration *)_configuration autoCommit:(BOOL)autoCommit;
-(id)initSqlSessionWithConfiguration:(Configuration *)_configuration autoCommit:(BOOL)autoCommit Transaction:(BOOL)_transaction;
@end
