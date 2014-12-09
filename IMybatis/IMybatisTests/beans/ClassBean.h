//
//  ClassBean.h
//  IMybatis
//
//  Created by 汪亚强 on 14-12-9.
//  Copyright (c) 2014年 wyq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClassBean : NSObject
@property int classID;
@property(nonatomic,strong)NSString *className;
@property(nonatomic,strong)NSArray *teacherArray;//统计有多少个老师
@property(nonatomic,strong)NSArray *studentArray;//统计有多少个学生
@end
