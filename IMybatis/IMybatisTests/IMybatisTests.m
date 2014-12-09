//
//  IMybatisTests.m
//  IMybatisTests
//
//  Created by 汪亚强 on 14-12-9.
//  Copyright (c) 2014年 wyq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Configuration.h"
#import "XMLConfigBuilder.h"
#import "SqlSessionFactory.h"
#import "DefaultSqlSessionFactory.h"
#import "UserBean.h"
#import "FMDB.h"





@interface IMybatisTests : XCTestCase

@end

@implementation IMybatisTests
-(id<SqlSession>)getSqlSession
{
    NSBundle *bundle=[NSBundle bundleForClass:[self class]];
    NSString *resource=[bundle pathForResource:@"conf" ofType:@"xml"];
    NSLog(@"%@",resource);
    //NSString *resource = @"/Users/wangyaqiang/Desktop/项目/YIMADSACarCopy4/YIMADSACarCopy/mybatis/conf.xml";
    //加载 mybatis 的配置文件(它也加载关联的映射文件)
    //构建 sqlSession 的工厂
    id<SqlSessionFactory> sessionFactory =[[DefaultSqlSessionFactory alloc]initSqlSessionFactoryWithConfigurationXMLFilePath:resource];
    //创建能执行映射文件中 sql 的 sqlSession
    id<SqlSession> session = [sessionFactory openSession];
    return session;
}
- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}
- (void)testXMLParse {
    Configuration *config=[[Configuration alloc]init];
    NSBundle *bundle=[NSBundle bundleForClass:[self class]];
    NSString *resource=[bundle pathForResource:@"conf" ofType:@"xml"];
    XMLConfigBuilder *bulider=[[XMLConfigBuilder alloc]initXMLConfigBuilderWithInputData:[NSData dataWithContentsOfFile:resource] configuration:config];
    [bulider parse];
    NSLog(@"%@",config);
    
}
-(void)testSelectOneUserWithInt
{
    id<SqlSession> session =[self getSqlSession];
    //映射 sql 的标识字符串
    NSString *statement =@"com.mybatis.userMapper.getUserWithInt";
    //执行查询返回一个唯一 user 对象的 sql
    UserBean *user = [session selectOne:statement parameter:@2];
    NSLog(@"=====%@",[user description]);
}
-(void)testSelectOneUserWithString
{
   id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getUserWithString";
   
    UserBean *user = [session selectOne:statement parameter:@"Tom"];
    NSLog(@"=====%@",[user description]);
}
-(void)testSelectListUserWithString
{
    id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getUserWithString";
    
    UserBean *user = [session selectList:statement parameter:@"Tom"];
    NSLog(@"=====%@",[user description]);
}

@end
