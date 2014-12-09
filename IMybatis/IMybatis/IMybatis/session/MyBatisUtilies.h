//
//  MyBatisUtilies.h
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-25.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyBatisUtilies : NSObject
+(NSArray *)getAllPropertysWithClassName:(NSString *)className;//根据类名获取所有属性
+(NSMutableDictionary *)getPropertyClassTypeAndName:(NSString *)objectName;//根据类名获取所有属性及属性的类型
@end
