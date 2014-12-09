//
//  DefaultSqlSessionFactory.m
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-17.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import "DefaultSqlSessionFactory.h"
#import "DefaultSqlSession.h"
#import "XMLConfigBuilder.h"
//默认自动提交
@implementation DefaultSqlSessionFactory
@synthesize configuration;
-(id)initSqlSessionFactoryWithConfiguration:(Configuration *)_configuration
{
    self=[super init];
    if (self) {
        self.configuration=_configuration;
    }
    return self;
}
-(id)initSqlSessionFactoryWithConfigurationXMLFilePath:(NSString *)filePath
{
    self=[super init];
    if (self) {
        self.configuration=[[Configuration alloc]init];
        XMLConfigBuilder *xmlBuilder=[[XMLConfigBuilder alloc]initXMLConfigBuilderWithInputData:[NSData dataWithContentsOfFile:filePath] configuration:self.configuration];
        [xmlBuilder parse];
    }
    return self;
}
-(id<SqlSession>) openSession
{
    return [self openSessionFromDataSource:self.configuration autoCommit:YES Transaction:NO];
}

//自动提交
-(id<SqlSession>) openSession:(BOOL) autoCommit
{
     return [self openSessionFromDataSource:self.configuration autoCommit:autoCommit Transaction:NO];
}
-(id<SqlSession>)openSessionFromDataSource:(Configuration *)config autoCommit:(BOOL)autoCommit Transaction:(BOOL)_transaction
{
    DefaultSqlSession *defaultSqlSession=[[DefaultSqlSession alloc]initSqlSessionWithConfiguration:configuration autoCommit:autoCommit Transaction:_transaction];
    return defaultSqlSession;
}
-(id<SqlSession>) openSession:(BOOL) autoCommit Transaction:(BOOL)_transaction
{
   return [self openSessionFromDataSource:self.configuration autoCommit:autoCommit Transaction:_transaction];
}
@end
