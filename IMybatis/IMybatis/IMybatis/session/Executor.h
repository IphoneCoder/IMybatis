//
//  Executor.h
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-23.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MappedStatement.h"
@protocol Executor <NSObject>
-(BOOL)update:(MappedStatement *)ms parameter:(id) parameter;
-(id)query:(MappedStatement *) ms parameter:(id)parameter;
-(void)commit;
-(void) rollback;
-(BOOL)isClosed;
-(void) close:(BOOL) forceRollback;
@end
