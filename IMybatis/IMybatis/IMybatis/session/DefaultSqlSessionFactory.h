//
//  DefaultSqlSessionFactory.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-17.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqlSessionFactory.h"
#import "Configuration.h"
@interface DefaultSqlSessionFactory : NSObject<SqlSessionFactory>
@property(nonatomic,strong)Configuration *configuration;
-(id)initSqlSessionFactoryWithConfiguration:(Configuration *)_configuration;
-(id)initSqlSessionFactoryWithConfigurationXMLFilePath:(NSString *)filePath;
@end
