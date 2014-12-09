//
//  BaseExecutor.h
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-23.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Executor.h"
#import "Configuration.h"
#import "FMDB.h"
@interface BaseExecutor : NSObject<Executor>
{
    dispatch_queue_t    _queue;
}
@property BOOL closed;
@property BOOL transaction;
@property BOOL autoCommit;
@property(nonatomic,strong)NSMutableArray *sqlArray;
@property(nonatomic,strong)Configuration *configuration;
@property(nonatomic,strong)FMDatabase *signalDb;
-(id)initWithConfigurationAndTransaction:(Configuration *)_configuration isTransaction:(BOOL)transaction;
-(id)initWithConfigurationAndTransaction:(Configuration *)_configuration isAutoCommit:(BOOL)_autoCommit isTransaction:(BOOL)transaction;
-(void) commit;
-(void) rollback;
@end
