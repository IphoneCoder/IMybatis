//
//  DefaultSqlSession.m
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-17.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import "DefaultSqlSession.h"
#import "MybatisCommonMacros.h"
#import "BaseExecutor.h"
#import "Executor.h"
#import "SimpleExecutor.h"
@implementation DefaultSqlSession
@synthesize configuration;
@synthesize autoCommit;
@synthesize transaction;
@synthesize defaultExecutor;
-(id)initSqlSessionWithConfiguration:(Configuration *)_configuration
{
    self=[super init];
    if (self) {
        self.configuration=_configuration;
        self.autoCommit=YES;//默认为yes
        self.transaction=NO;//默认不用事务
       self.defaultExecutor=[[BaseExecutor alloc]initWithConfigurationAndTransaction:self.configuration isAutoCommit:self.autoCommit isTransaction:self.transaction];
    }
    return self;
}
-(id)initSqlSessionWithConfiguration:(Configuration *)_configuration autoCommit:(BOOL)_autoCommit
{
    self=[super init];
    if (self) {
        self.configuration=_configuration;
        self.autoCommit=_autoCommit;
        self.transaction=NO;//默认不用事务
        self.defaultExecutor=[[BaseExecutor alloc]initWithConfigurationAndTransaction:self.configuration isAutoCommit:self.autoCommit isTransaction:self.transaction];
    }
    return self;
}

-(id)initSqlSessionWithConfiguration:(Configuration *)_configuration autoCommit:(BOOL)_autoCommit Transaction:(BOOL)_transaction
{
    self=[super init];
    if (self) {
        self.configuration=_configuration;
        self.autoCommit=_autoCommit;
        self.transaction=_transaction;
        self.defaultExecutor=[[BaseExecutor alloc]initWithConfigurationAndTransaction:self.configuration isAutoCommit:self.autoCommit isTransaction:self.transaction];
    }
    return self;

}
-(id) selectOne:(NSString  *) statement
{
    
    NSArray *array=[self selectList:statement parameter:nil];
    if (array.count==0) {
        return nil;
    }
    if (array.count==1) {
        return [array objectAtIndex:0];
    }else
    {
        NSString *reason=[NSString stringWithFormat:@"Expected one result (or null) to be returned by selectOne(), but found:%d",array.count];
        ThrowException(@"DefaultSqlSession", reason, nil);
    }
    return nil;
}


-(id) selectOne:(NSString *) statement parameter:(id) parameter
{
    NSArray *array=[self selectList:statement parameter:parameter];
    if (array.count==0) {
        return nil;
    }
    if (array.count==1) {
        return [array objectAtIndex:0];
    }else
    {
        NSString *reason=[NSString stringWithFormat:@"Expected one result (or null) to be returned by selectOne(), but found:%ld",array.count];
        ThrowException(@"DefaultSqlSession", reason, nil);
    }
    return nil;
}


-(id) selectList:(NSString *) statement
{
    return  [self selectList:statement parameter:nil];
   // return nil;
}


-(id) selectList:(NSString *) statement parameter:(id) parameter
{
    MappedStatement *executeState=[self.configuration.mappedStatementDic objectForKey:statement];
    if (executeState==nil) {
        NSString *reason=[NSString stringWithFormat:@"can not find %@",statement];
        ThrowException(@"DefaultSqlSession", reason, nil);
    }
    //id<Executor>executor=[[BaseExecutor alloc]initWithConfigurationAndTransaction:self.configuration isTransaction:NO];
    id<Executor>executor=[[SimpleExecutor alloc]initWithConfigurationAndTransaction:self.configuration isTransaction:NO];
    if (executeState.mapperType==MapperTypeSelect) {
       return  [executor query:executeState parameter:parameter];
    }
    
    
    
    return nil;
}


-(NSDictionary *) selectMap:(NSString *) statement mapKey:(NSString *) mapKey
{
    return nil;
}


-(NSDictionary *) selectMap:(NSString *) statement parameter:(id) parameter mapKey:(NSString *) mapKey
{
    return nil;
}


-(BOOL) insert:(NSString *) statement
{
   return  [self insert:statement parameter:nil];
    
}


-(BOOL) insert:(NSString *) statement parameter:(id)parameter
{
    MappedStatement *executeState=[self.configuration.mappedStatementDic objectForKey:statement];
    return  [self.defaultExecutor update:executeState parameter:parameter];
    
   // return -1;
}


-(BOOL) update:(NSString *) statement
{
    return [self insert:statement];
    
}


-(BOOL) update:(NSString *) statement parameter:(id) parameter
{
    
    return [self insert:statement parameter:parameter];
}


-(BOOL) delete:(NSString *) statement
{
    
    return [self insert:statement];
}


-(BOOL) delete:(NSString *) statement  parameter:(id) parameter
{
    return [self delete:statement parameter:parameter];
}


-(void) commit
{
    [self.defaultExecutor commit];
}


-(void) commit:(BOOL) force
{

}


-(void) rollback
{

}



-(void) rollback:(BOOL) force
{

}


-(void) close
{

}

-(void) clearCache
{

}
@end
