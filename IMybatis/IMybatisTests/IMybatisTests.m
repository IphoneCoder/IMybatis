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
-(void)testSelectOneUserWithInt //参数是int
{
    id<SqlSession> session =[self getSqlSession];
    //映射 sql 的标识字符串
    NSString *statement =@"com.mybatis.userMapper.getUserWithInt";
    //执行查询返回一个唯一 user 对象的 sql
    UserBean *user = [session selectOne:statement parameter:@2];
    NSLog(@"=====%@",[user description]);
}
-(void)testSelectOneUserWithString //参数是string,返回结果是单个对象
{
    
   id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getUserWithString";
   //如果调用selectOne 但是有多条记录，会抛出异常
    UserBean *user = [session selectOne:statement parameter:@"Tom"];
    NSLog(@"=====%@",[user description]);
}
-(void)testSelectListUserWithString //参数是string,返回结果是多个对象
{
    id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getUserWithString";
    
   NSArray *userArray= [session selectList:statement parameter:@"Tom"];
    NSLog(@"=====%lu",(unsigned long)userArray.count);
}


-(void)testSelectOneUserWithDictionary //参数是map,返回结果是单个对象
{
   id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getUserWithMap";
    //执行查询返回一个唯一 user 对象的 sql
    UserBean *user = [session selectOne:statement parameter:[NSDictionary dictionaryWithObject:@1 forKey:@"id"]];
    NSLog(@"=====%@",[user description]);
    
}
//省略 参数是map,返回结果是多个对象得测试，直接调用 session selectList即可



-(void)testSelectOneUserWithObject //参数是object,返回结果是单个对象
{
   id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getUserWithObject";
    //执行查询返回一个唯一 user 对象的 sql
    UserBean *userBean=[[UserBean alloc]init];
    userBean.userID=2;
    UserBean *user = [session selectOne:statement parameter:userBean];
    NSLog(@"=====%@",[user description]);
    
}
//省略 参数是object,返回结果是多个对象得测试，直接调用 session selectList即可

-(void)testSelectOneUserWithResultMap //参数是int,返回结果是单个对象,使用resultMap映射
{
    id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getOneUserResultMap";
    //执行查询返回一个唯一 user 对象的 sql
    UserBean *userBean = [session selectOne:statement parameter:@2];
    NSLog(@"=====%@",[userBean description]);
    
}
-(void)testSelectListUserWithResultMap //参数是int,返回结果是多个对象,使用resultMap映射
{
   id<SqlSession> session =[self getSqlSession];
    NSString *statement =@"com.mybatis.userMapper.getListUserResultMap";
    //执行查询返回一个唯一 user 对象的 sql
    NSArray *userBeanArray = [session selectList:statement parameter:@"Tom"];
    for (UserBean *userBean in userBeanArray) {
        NSLog(@"=====%@",[userBean description]);
    }
}
@end
