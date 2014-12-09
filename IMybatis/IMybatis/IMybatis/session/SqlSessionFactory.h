//
//  DSASqlSessionFactory.h
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-16.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqlSession.h"
@protocol SqlSessionFactory <NSObject>
-(id<SqlSession>) openSession;

//自动提交
-(id<SqlSession>) openSession:(BOOL) autoCommit;
-(id<SqlSession>) openSession:(BOOL) autoCommit Transaction:(BOOL)_transaction;
@end
