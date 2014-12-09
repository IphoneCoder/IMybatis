//
//  CollectionStatement.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-12-2.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CollectionStatement : NSObject
@property(nonatomic,strong)NSString *collectionType;
@property(nonatomic,strong)NSMutableDictionary *collectionPropertyIdDic;//id property
@property(nonatomic,strong)NSString *collectionProperty;
@property(nonatomic,strong)NSMutableDictionary *collectionDic;
@property(nonatomic,strong)NSMutableArray *collectionArray;
@property(nonatomic,strong)NSMutableDictionary* collectionAttributeDataDic;
@property(nonatomic,strong)NSMutableDictionary *collectionDataDic;//里边存放CollectionStatement
@property(nonatomic,strong)NSMutableDictionary *associatioDataDic;//里边存放AssociationStatement
@property(nonatomic,strong)NSMutableDictionary *collectionReversalDic;
@end
