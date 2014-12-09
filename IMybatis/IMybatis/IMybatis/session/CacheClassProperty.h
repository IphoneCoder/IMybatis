//
//  CacheClassProperty.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-12-8.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheClassProperty : NSObject
@property(nonatomic,strong)NSMutableDictionary *classImpDic;//字典里边存字典
@property(nonatomic,strong)NSNumberFormatter *numberFormatter;//字典里边存字典
+ (instancetype)sharedInstance;
@end
