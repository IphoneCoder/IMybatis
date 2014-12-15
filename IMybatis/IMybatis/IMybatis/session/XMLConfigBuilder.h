//
//  XMLConfigBuilder.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-17.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Configuration;
@interface XMLConfigBuilder : NSObject
@property(nonatomic,weak)Configuration *configuration;
@property(nonatomic,strong)NSInputStream *inputStream;
@property(nonatomic,strong)NSData *inputData;
@property(nonatomic,strong)NSMutableArray *parseObjectArray;
-(id)initXMLConfigBuilderWithInputStream:(NSInputStream *)inputStream configuration:(Configuration *)_configuration;
-(id)initXMLConfigBuilderWithInputData:(NSData *)_inputData configuration:(Configuration *)_configuration;
-(Configuration *)parse;
-(void)mapperFileParse:(NSString *)mapperFileName;
@end
