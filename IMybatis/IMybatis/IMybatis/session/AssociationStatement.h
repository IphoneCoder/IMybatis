//
//  AssociationStatement.h
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-27.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AssociationStatement : NSObject
@property(nonatomic,strong)NSString *associationType;
@property(nonatomic,strong)NSMutableDictionary *associationPropertyIdDic;//id property
@property(nonatomic,strong)NSString *associationProperty;
@property(nonatomic,strong)NSMutableDictionary *associatioDic;
@property(nonatomic,strong)NSMutableDictionary *associatioReversalDic;
@property(nonatomic,strong)NSMutableArray *associatioArray;
@property(nonatomic,strong)NSMutableDictionary* associatioAttributeDataDic;
@property(nonatomic,strong)NSMutableDictionary *associatioDataDic;//里边存放AssociationStatement
@property(nonatomic,strong)NSMutableDictionary *collectionDataDic;//里边存放CollectionStatement
@end
