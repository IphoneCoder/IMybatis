//
//  TeacherBean.h
//  IMybatis
//
//  Created by 汪亚强 on 14-12-9.
//  Copyright (c) 2014年 wyq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeacherBean : NSObject
@property int teacherID;
@property(nonatomic,strong)NSString *teacherName;
@property(nonatomic,strong)NSArray *studentArray;//统计有多少个学生
@end
