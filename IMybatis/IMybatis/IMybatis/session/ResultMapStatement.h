//
//  ResultMapStatement.h
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-26.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResultMapStatement : NSObject
@property(nonatomic,strong)NSString *resultMapType;
@property(nonatomic,strong)NSString *resultMapNameSpace;
@property(nonatomic,strong)NSString *resultMapId;
@property(nonatomic,strong)NSMutableDictionary *resultMapPropertyIdDic;
@property(nonatomic,strong)NSMutableArray *resultMapArray;//resultMapArray和resultMapDic 存放的东西一样
@property(nonatomic,strong)NSMutableDictionary *resultMapDic;
@property(nonatomic,strong)NSMutableDictionary *resultMapReversalDic;
@property(nonatomic,strong)NSMutableDictionary* resultMapAttributeDataDic;
@property(nonatomic,strong)NSMutableDictionary *associationStatementDic;
@property(nonatomic,strong)NSMutableDictionary *collectionStatementDic;//里边存放CollectionStatement
@end
