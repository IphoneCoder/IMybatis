//
//  BaseExecutor.m
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-23.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//



/*==========================


 //
 //    NSString *string=@"select * from users where id=#{id}";
 //    NSError *error;
 //    // NSString *regulaStr = @"#{\\w+}";
 //    NSString *regulaStr = @"#\\{(\\w+)\\}";
 //
 //    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
 //                                                                           options:NSRegularExpressionCaseInsensitive
 //                                                                             error:&error];
 //    NSArray *arrayOfAllMatches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
 //
 //    for (NSTextCheckingResult *match in arrayOfAllMatches)
 //    {
 //        NSString* substringForMatch = [string substringWithRange:match.range];
 //        NSError *error1;
 //        NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)"
 //                                                                                options:NSRegularExpressionCaseInsensitive
 //                                                                                  error:&error1];
 //        NSArray *array=[regex1 matchesInString:substringForMatch options:0 range:NSMakeRange(0, [substringForMatch length])];
 //        for (NSTextCheckingResult *match1 in array) {
 //            NSString *ttt=[substringForMatch substringWithRange:match1.range];
 //            NSLog(@"tttttt===%@",ttt);
 //        }
 //        NSLog(@"substringForMatch====%@",substringForMatch);
 //    }
 

 
 
 unsigned int numIvars;
 Method *methods= class_copyMethodList(class, &numIvars);
 for(int i = 0; i < numIvars; i++) {
 
 Method thisIvar = methods[i];
 IMP imp=method_getImplementation(thisIvar);
 NSValue *value=[NSValue valueWithPointer:imp];
 SEL sel = method_getName(thisIvar);
 const char *name = sel_getName(sel);
 NSLog(@"%s",name);
 }
 free(methods);


*/

#import "SimpleExecutor.h"
#import "MybatisCommonMacros.h"
#import "FMDB.h"
#import "MyBatisUtilies.h"
#import "AssociationStatement.h"
#import "CollectionStatement.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "CacheClassProperty.h"
@implementation SimpleExecutor
@synthesize closed;
@synthesize transaction;
@synthesize configuration;
@synthesize autoCommit;
@synthesize signalDb;
@synthesize sqlArray;
#define mybatis_repat  @"mybatis_occupation_repatDic"
static const void * const mybatisDispatchQueueSpecificKey = &mybatisDispatchQueueSpecificKey;
-(id)initWithConfigurationAndTransaction:(Configuration *)_configuration isTransaction:(BOOL)_transaction
{
    self=[super init];
    if (self) {
        self.configuration=_configuration;
        self.transaction=_transaction;
        self.sqlArray=[NSMutableArray arrayWithCapacity:0];
    }
    return self;
}
-(id)initWithConfigurationAndTransaction:(Configuration *)_configuration isAutoCommit:(BOOL)_autoCommit isTransaction:(BOOL)_transaction
{
    self=[super init];
    if (self) {
        self.configuration=_configuration;
        self.transaction=_transaction;
        self.autoCommit=_autoCommit;
        self.sqlArray=[NSMutableArray arrayWithCapacity:0];
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
        dispatch_queue_set_specific(_queue, mybatisDispatchQueueSpecificKey, (__bridge void *)self, NULL);
        self.signalDb=[FMDatabase databaseWithPath:self.configuration.databasePath];
    }
    return self;
}
-(BOOL)update:(MappedStatement *)ms parameter:(id) parameter
{
    
    if (ms==nil) {
        ThrowException(@"BaseExecutor",@"can not find statement", nil);
    }
    if (self.closed) {
        ThrowException(@"BaseExecutor", @"Executor was closed.", nil);
        return NO;
    }
    NSString *executeSql=[self disposeSql:ms parameter:parameter];
     [self.sqlArray addObject:executeSql];
    if (self.autoCommit==YES) {
        
        return [self executeWithTrans:self.transaction];
    }else
        if (self.autoCommit==NO) {
            return YES;
//            dispatch_sync(_queue, ^() {
//                
//                BOOL shouldRollback = NO;
//                
//                
//                [self.signalDb beginTransaction];
//                
//                
//                block(self.signalDb, &shouldRollback);
//                
//                if (shouldRollback) {
//                    [self.signalDb rollback];
//                }
//                else {
//                    [self.signalDb commit];
//                }
//            });
        }
    return NO;
}
-(void) commit
{
    if (self.autoCommit==YES) {
        return;
    }
    [self executeWithTrans:self.transaction];
}
-(BOOL)executeWithTrans:(BOOL)trans
{
    __block BOOL b=YES;
    if (self.transaction==YES) {
        [self.configuration.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            for (int i=0; i<self.sqlArray.count; i++) {
                NSString *sql=[self.sqlArray objectAtIndex:i];
                if ([sql isKindOfClass:[NSString class]]&&sql.length>0) {
                    b=b&&[db executeUpdate:sql];
                }
            }
            *rollback=!b;
            
            [self.sqlArray removeAllObjects];
        }];
    }else
    {
        [self.configuration.databaseQueue inDatabase:^(FMDatabase *db) {
            for (int i=0; i<self.sqlArray.count; i++) {
                NSString *sql=[self.sqlArray objectAtIndex:i];
                if ([sql isKindOfClass:[NSString class]]&&sql.length>0) {
                    b=b&&[db executeUpdate:sql];
                }
            }
            [self.sqlArray removeAllObjects];
        }];

    }
    return b;

}
-(void) rollback
{
    //为实现
}
-(id)query:(MappedStatement *) ms parameter:(id)parameter
{
    if (ms==nil) {
        
        ThrowException(@"BaseExecutor",@"can not find statement", nil);
    }
    return  [self queryFromDatabase:ms parameter:parameter];
}
-(NSString *)checkParameterType:(MappedStatement *)ms
{
    NSString *lowParameterType=ms.mapperParameterType.lowercaseString;
    NSString *parameterType=nil;
    if ([lowParameterType isEqualToString:@"int"]||[lowParameterType isEqualToString:@"float"]||[lowParameterType isEqualToString:@"double"]) {
        parameterType= @"number";
    }else
    {
        parameterType=ms.mapperParameterType;
    }
    return parameterType;
}
-(NSString *)disposeSql:(MappedStatement *)ms parameter:(id)parameter
{
    if (parameter==nil) {
        return ms.mapperSqlSource;
    }
    NSError *error;
    NSString *regulaStr = @"#\\{(\\w+)\\}";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *arrayOfAllMatches = [regex matchesInString:ms.mapperSqlSource options:0 range:NSMakeRange(0, [ms.mapperSqlSource length])];
    NSString *oriSql=ms.mapperSqlSource;
    NSString *resultStr=oriSql;
    NSString *checkParameterType=[self checkParameterType:ms];
    if ([parameter isKindOfClass:[NSNumber class]]) {//基本数据类型
        
        if (![checkParameterType.lowercaseString isEqualToString:@"number"]) {
            NSString *reason=[NSString stringWithFormat:@"%@ parameterType need %@ type but pass %@",ms.mapperID,ms.mapperParameterType,[parameter class]];
            ThrowException(@"BaseExecutor",reason, nil);
        }
        // 2008-07-01 19:03:03.195 test[68775:813] replaced string: '{This} {is} {neat}.'
        
        //NSString *string=@"select * from users where id=#{id}";
        
        for (NSTextCheckingResult *match in arrayOfAllMatches)
        {
            NSString* substringForMatch = [oriSql substringWithRange:match.range];
            resultStr=[resultStr stringByReplacingOccurrencesOfString:substringForMatch withString:[NSString stringWithFormat:@"%@",parameter]];
            
        }
        
       
    }else if([parameter isKindOfClass:[NSString class]])
    {
        if (![checkParameterType.lowercaseString isEqualToString:@"string"]) {
            NSString *reason=[NSString stringWithFormat:@"%@ parameterType need %@ type but pass %@",ms.mapperID,ms.mapperParameterType,[parameter class]];
            ThrowException(@"BaseExecutor",reason, nil);
        }
        
        for (NSTextCheckingResult *match in arrayOfAllMatches)
        {
            NSString* substringForMatch = [oriSql substringWithRange:match.range];
            resultStr=[resultStr stringByReplacingOccurrencesOfString:substringForMatch withString:[NSString stringWithFormat:@"'%@'",parameter]];
            
        }
      
        
    }else if ([parameter isKindOfClass:[NSObject class]])
    {
        for (NSTextCheckingResult *match in arrayOfAllMatches)
        {
            NSString* substringForMatch = [oriSql substringWithRange:match.range];
            NSError *ssuberror;
            NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)"options:NSRegularExpressionCaseInsensitive                                                                         error:&ssuberror];
            NSArray *array=[regex1 matchesInString:substringForMatch options:0 range:NSMakeRange(0, [substringForMatch length])];
            if (array.count!=1) {
                NSString *reason=[NSString stringWithFormat:@"%@ pase error",substringForMatch];
                ThrowException(@"BaseExecutor",reason, nil);
            }
            NSTextCheckingResult *match1=[array objectAtIndex:0];
            NSString *ttt=[substringForMatch substringWithRange:match1.range];
            if ([parameter isKindOfClass:[NSDictionary class]]) {
                if (![checkParameterType.lowercaseString isEqualToString:@"map"]) {
                    NSString *reason=[NSString stringWithFormat:@"%@ parameterType need %@ type but pass %@",ms.mapperID,ms.mapperParameterType,[parameter class]];
                    ThrowException(@"BaseExecutor",reason, nil);
                }
                
                resultStr=[resultStr stringByReplacingOccurrencesOfString:substringForMatch withString:[NSString stringWithFormat:@"'%@'",[parameter objectForKey:ttt]]];
            }else
            {
                if (![checkParameterType.lowercaseString isEqualToString:[NSStringFromClass([parameter class]) lowercaseString]]) {
                    NSString *reason=[NSString stringWithFormat:@"%@ parameterType need %@ type but pass %@",ms.mapperID,ms.mapperParameterType,[parameter class]];
                    ThrowException(@"BaseExecutor",reason, nil);
                }
                NSArray *propertyArray=[MyBatisUtilies getAllPropertysWithClassName:[NSString stringWithFormat:@"%@",[parameter class]]];
                if ([propertyArray containsObject:ttt]) {
                    resultStr=[resultStr stringByReplacingOccurrencesOfString:substringForMatch withString:[NSString stringWithFormat:@"'%@'",[parameter valueForKey:ttt]]];
                }
            }
            
            
        }
        
    }
    NSLog(@"正在执行%@",resultStr);
    return resultStr;
}
//加这个方法是为了以后如果有缓冲
-(id)queryFromDatabase:(MappedStatement *)ms parameter:(id)parameter
{
    
    NSString *resultStr=[self disposeSql:ms parameter:parameter];
    NSLog(@"执行sql===%@",resultStr);
    __block NSMutableArray *resultDataMutArray=nil;
    [self.configuration.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *type=@"";
        FMResultSet*set=[db executeQuery:resultStr];
        int coloumCount=[set columnCount];
        NSString *resultMapStr=ms.mapperResultMap;
        NSString *resultTypeStr=ms.mapperResultType;
        ResultMapStatement *resultMapStatement=nil;
        if (resultMapStr.length<=0&&resultTypeStr.length<=0) {
            [set close];
            NSString *reason=[NSString stringWithFormat:@"%@ must have resultMap or resultType but can not all null",ms.mapperID];
            ThrowException(@"BaseExecutor",reason, nil);
        }else
        if (resultTypeStr.length>0&&resultMapStr>0) {
            [set close];
            NSString *reason=[NSString stringWithFormat:@"%@ must have resultMap or resultType but can not both not null",ms.mapperID];
            ThrowException(@"BaseExecutor",reason, nil);

        }else
            if (resultTypeStr.length>0&&resultMapStr<=0) {
                type=resultTypeStr;
                if ([resultTypeStr.lowercaseString isEqualToString:@"map"]) {
                    resultDataMutArray=[self resultDataTypeNSDictionary:set coloumCount:coloumCount];
                    
                }else
                if ([resultTypeStr.lowercaseString isEqualToString:@"int"]) {
                    resultDataMutArray=[self resultDataTypeNSNumber:set coloumCount:coloumCount];
                   
                }else
                if ([resultTypeStr.lowercaseString isEqualToString:@"float"]) {
                    resultDataMutArray=[self resultDataTypeNSNumber:set coloumCount:coloumCount];
                    
                }else
                if ([resultTypeStr.lowercaseString isEqualToString:@"double"]) {
                    resultDataMutArray=[self resultDataTypeNSNumber:set coloumCount:coloumCount];
                    
                }
                else
                {
                    resultDataMutArray=[self resultDataTypeNSObjectWithSetAndType:nil sourceSet:set columCount:coloumCount type:resultTypeStr];
                    
                }
        }else if (resultTypeStr.length<=0&&resultMapStr>0)
        {
            
            NSString *trueResultMapID=[NSString stringWithFormat:@"%@.%@",ms.mapperNamespace,resultMapStr];
            resultMapStatement=[self.configuration.resultMapStatementDic objectForKey:trueResultMapID];
            if (resultMapStatement==nil) {
                [set close];
                NSString *reason=[NSString stringWithFormat:@"can not find map %@",trueResultMapID];
                ThrowException(@"BaseExecutor",reason, nil);
            }
           resultDataMutArray=[self resultDataTypeNSObjectWithSetAndType:resultMapStatement sourceSet:set columCount:coloumCount type:resultMapStatement.resultMapType];
            
        }
    }];
    return resultDataMutArray;
}

-(NSMutableDictionary *)dataBaseColumConvertToDic:(FMResultSet *)set columCount:(int)columCount
{
    NSMutableDictionary *resultDic=[NSMutableDictionary dictionaryWithCapacity:0];
    for (int i=0; i<columCount; i++) {
        NSString *coloumName=[set columnNameForIndex:i];
        NSString *coloumValue=[set stringForColumnIndex:i];
        if (coloumName.length<=0) {
            ThrowException(@"BaseExecutor",@"table coloum name  can not null", nil);
        }
        if (coloumValue.length<=0) {
            coloumValue=@"";
        }
        [resultDic setObject:coloumValue forKey:coloumName];
    }
    return resultDic;
}
-(NSMutableArray *)resultDataTypeNSObjectWithSetAndType:(ResultMapStatement *)resultMapStatement sourceSet:(FMResultSet *)sourceSet columCount:(int)columnCount type:(NSString *)type
{
    NSMutableArray *mutArray=[NSMutableArray arrayWithCapacity:0];
    NSMutableDictionary *filterRepatDic=[NSMutableDictionary dictionaryWithCapacity:0];
    while ([sourceSet next]) {
        NSDictionary *oriDic=[self dataBaseColumConvertToDic:sourceSet columCount:columnCount];
       // sourceSet.resultDictionary;
       
        if (oriDic==nil) {
            return nil;
        }
        id parentElement=nil;
        id object=nil;
        if (resultMapStatement==nil) {
            object=[self resultDataTypeNSObjectWithNSDictionary:oriDic resultType:type];
        }else
        {
            object=[self resultDataMapNSObjectWithNSDictionaryArrayAndMapDic:oriDic resultType:type mapDic:resultMapStatement.resultMapReversalDic];
        }
       // object= [self resultDataTypeNSObjectWithNSDictionaryArrayAndMapDic:oriDic resultType:type mapDic:resultMapStatement.resultMapReversalDic];
    
            NSDictionary *propertyIDDic=resultMapStatement.resultMapPropertyIdDic;
            if (propertyIDDic!=nil) {
                NSString *coloum=[propertyIDDic objectForKey:@"column"];
                id propertyID=[oriDic valueForKey:coloum];
                if (propertyID==nil) {
                    parentElement=object;
                }else
                {
                    id repeatObject=[filterRepatDic objectForKey:propertyID];
                    if (repeatObject!=nil) {
                        parentElement=repeatObject;
                    }else
                    {
                        parentElement=object;
                        [mutArray addObject:object];
                        [filterRepatDic setObject:object forKey:propertyID];
                    }
                }
            }else
            {
                parentElement=object;
                [mutArray addObject:object];
                
            }
        if (parentElement==nil) {
            continue;
        }
       
        id undefineValue=nil;
        @try {
            undefineValue=objc_getAssociatedObject(parentElement, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding]);//[parentElement valueForKey:mybatis_repat];
        }
        @catch (NSException *exception) {
            undefineValue=nil;
        }
        @finally {
            
        }
        
        if (undefineValue==nil) {
            objc_setAssociatedObject(parentElement, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding], [NSMutableDictionary dictionaryWithCapacity:0], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
         NSDictionary *assoDic=resultMapStatement.associationStatementDic;
        NSDictionary *collectionDic=resultMapStatement.collectionStatementDic;
        if (assoDic!=nil) {
            [self setValueRecurrence:assoDic parentObject:parentElement sourceDic:oriDic];
        }
        if (collectionDic!=nil) {
            [self setValueCollectionRecurrence:resultMapStatement.collectionStatementDic parentObject:parentElement sourceDic:oriDic];
        }
        
        


    }
    [filterRepatDic removeAllObjects];
    filterRepatDic=nil;
    return mutArray;
}





-(void)setValueRecurrence:(NSDictionary *)assoDic parentObject:(id)parentObject sourceDic:(NSDictionary *)sourceDic
{
    if (assoDic!=nil&&[assoDic isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *propertyDic=[MyBatisUtilies getPropertyClassTypeAndName:NSStringFromClass([parentObject class])];
        NSMutableDictionary * filterRepatDic=objc_getAssociatedObject(parentObject, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding]);//[parentObject valueForUndefinedKey:mybatis_repat];//[NSMutableDictionary dictionaryWithCapacity:0];
        for (int i=0; i<assoDic.allKeys.count; i++) {
             id parentElement=nil;
            NSString *key=[assoDic.allKeys objectAtIndex:i];
            AssociationStatement *associationStatement=[assoDic objectForKey:key];
            if ([propertyDic objectForKey:associationStatement.associationProperty]==nil) {
                continue;
            }
            
            if (associationStatement!=nil&&[associationStatement isKindOfClass:[AssociationStatement class]]) {
                id obj=[self resultDataMapNSObjectWithNSDictionaryArrayAndMapDic:sourceDic resultType:associationStatement.associationType mapDic:associationStatement.associatioReversalDic];//[self resultDataTypeNSObjectWithNSDictionaryArrayAndMapDic:sourceDic resultType:associationStatement.associationType mapDic:associationStatement.associatioReversalDic];
                
                
                    NSString *type=[propertyDic objectForKey:associationStatement.associationProperty];
                    if ([type isEqualToString:associationStatement.associationType]) {
                        NSDictionary *propertyIDDic=associationStatement.associationPropertyIdDic;
                        if (propertyIDDic!=nil&&[propertyIDDic isKindOfClass:[NSDictionary class]]&&propertyIDDic.allKeys.count>0) {
                            NSString *property=[propertyIDDic objectForKey:@"property"];
                           // NSString *coloum=[propertyIDDic objectForKey:@"column"];
                            NSString *propertyID=[[obj valueForKey:property]stringValue];
                            if (propertyID.length<=0) {
                                propertyID=@"";
                            }
                            id repeatObject=[filterRepatDic objectForKey:propertyID];
                            if (repeatObject!=nil) {
                                parentElement=repeatObject;
                            }else
                            {
                                parentElement=obj;
                                [filterRepatDic setObject:obj forKey:propertyID];
                                [parentObject setValue:obj forKey:associationStatement.associationProperty];
                            }

                        }else
                        {
                            parentElement=obj;
                            [parentObject setValue:obj forKey:associationStatement.associationProperty];
                        }
                        id undefineValue=nil;
                        @try {
                            undefineValue=objc_getAssociatedObject(parentElement, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding]);//[parentElement valueForKey:mybatis_repat];
                        }
                        @catch (NSException *exception) {
                            undefineValue=nil;
                        }
                        @finally {
                            
                        }
                        
                        if (undefineValue==nil) {
                            objc_setAssociatedObject(parentElement, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding], [NSMutableDictionary dictionaryWithCapacity:0], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                            //[parentElement setValue:[NSMutableDictionary dictionaryWithCapacity:0] forKey:mybatis_repat];
                        }

                        [self setValueRecurrence:associationStatement.associatioDataDic parentObject:parentElement sourceDic:sourceDic];
                        [self setValueCollectionRecurrence:associationStatement.collectionDataDic parentObject:parentElement sourceDic:sourceDic];
                    }
       
                
                
            }
            
        }
    }
}
-(void)setValueCollectionRecurrence:(NSDictionary *)assoDic parentObject:(id)parentObject sourceDic:(NSDictionary *)sourceDic
{
    
    if (assoDic!=nil&&[assoDic isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *propertyDic=[MyBatisUtilies getPropertyClassTypeAndName:NSStringFromClass([parentObject class])];
        NSMutableDictionary *filterRepatDic=objc_getAssociatedObject(parentObject, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding]);//[parentObject valueForUndefinedKey:mybatis_repat];//[NSMutableDictionary dictionaryWithCapacity:0];
        for (int i=0; i<assoDic.allKeys.count; i++) {
            id parentElement=nil;
            NSString *key=[assoDic.allKeys objectAtIndex:i];
            CollectionStatement *associationStatement=[assoDic objectForKey:key];
            if ([propertyDic objectForKey:associationStatement.collectionProperty]==nil) {
                continue;
            }
            
            if (associationStatement!=nil&&[associationStatement isKindOfClass:[CollectionStatement class]]) {
                id obj=[self resultDataMapNSObjectWithNSDictionaryArrayAndMapDic:sourceDic resultType:associationStatement.collectionType mapDic:associationStatement.collectionReversalDic];
                    NSString *type=[propertyDic objectForKey:associationStatement.collectionProperty];
                    if ([type isEqualToString:@"@\"NSMutableArray\""]||[type isEqualToString:@"@\"NSArray\""]) {
                       // id obj=[coverObjectArray firstObject];
                        NSMutableArray *mutA=[parentObject valueForKey:associationStatement.collectionProperty];
                        if (mutA==nil||![mutA isKindOfClass:[NSArray class]]) {
                            mutA=[NSMutableArray arrayWithCapacity:0];
                        }
                        if (obj!=nil) {
                
                            NSDictionary *propertyIDDic=associationStatement.collectionPropertyIdDic;
                            if (propertyIDDic!=nil) {
                                NSString *property=[propertyIDDic objectForKey:@"property"];
                                // NSString *coloum=[propertyIDDic objectForKey:@"column"];
                                id value=[obj valueForKey:property];
                                
                               
                                //[[obj valueForKey:property]stringValue];
                                if (value==nil) {
                                    parentElement=obj;
                                    [mutA addObject:obj];
                                }else
                                {
                                    id repeatObject=[filterRepatDic objectForKey:value];
                                    if (repeatObject!=nil) {
                                        parentElement=repeatObject;
                                    }else
                                    {
                                        parentElement=obj;
                                        [filterRepatDic setObject:obj forKey:value];
                                        [mutA addObject:obj];
                                        [parentObject setValue:mutA forKey:associationStatement.collectionProperty];
                                    }

                                }
                                
                            }else
                            {
                                parentElement=obj;
                                [mutA addObject:obj];
                                //[parentObject setValue:mutA forKey:associationStatement.collectionProperty];
                            }
                            
                        }
                        if (parentElement!=nil) {
                            id undefineValue=nil;
                            @try {
                                undefineValue=objc_getAssociatedObject(parentElement, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding]);//[parentElement valueForKey:mybatis_repat];
                            }
                            @catch (NSException *exception) {
                                undefineValue=nil;
                            }
                            @finally {
                                
                            }
                            
                            if (undefineValue==nil) {
                                objc_setAssociatedObject(parentElement, [mybatis_repat cStringUsingEncoding:NSUTF8StringEncoding], [NSMutableDictionary dictionaryWithCapacity:0], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                                //[parentElement setValue:[NSMutableDictionary dictionaryWithCapacity:0] forKey:mybatis_repat];
                            }
                            [self setValueCollectionRecurrence:associationStatement.collectionDataDic parentObject:parentElement sourceDic:sourceDic];
                            [self setValueRecurrence:associationStatement.associatioDataDic parentObject:parentElement sourceDic:sourceDic];
                        }
                        
                    }else
                    {
                        NSString *reason=[NSString stringWithFormat:@"%@ collection must Array",associationStatement.collectionProperty];
                        ThrowException(@"BaseExecutor",reason, nil);
                    }
                
                
            }
            
        }
    }
}

-(NSMutableArray *)resultDataTypeNSNumber:(FMResultSet *)set coloumCount:(int)coloumCount
{
    
    if (coloumCount>1) {
        ThrowException(@"BaseExecutor",@"expect one column but more", nil);
    }
    if (coloumCount<=0) {
        ThrowException(@"BaseExecutor",@"expect one or more column but zero", nil);
    }
    NSMutableArray *resultDataMutArray=[NSMutableArray arrayWithCapacity:0];
    while ([set next]) {
        NSString *stringValue=[set stringForColumnIndex:0];
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        NSNumber *resultNumber=[numberFormatter numberFromString:stringValue];
        if (resultNumber!=nil) {
            [resultDataMutArray addObject:resultNumber];
        }else
        {
            NSString *reason=[NSString stringWithFormat:@"%@ can not convert nsnumber type",stringValue];
            ThrowException(@"BaseExecutor",reason, nil);
        }
    }
    return resultDataMutArray;
}
-(NSMutableArray *)resultDataTypeNSDictionary:(FMResultSet *)set coloumCount:(int)coloumCount
{
    NSMutableArray *resultDataMutArray=[NSMutableArray arrayWithCapacity:0];
    
    while ([set next]) {
        NSMutableDictionary *tempMutDic=[NSMutableDictionary dictionaryWithCapacity:0];
        for (int i=0; i<coloumCount; i++) {
            NSString *coloumName=[set columnNameForIndex:i];
            NSString *coloumValue=[set stringForColumnIndex:i];
            if (coloumName.length<=0) {
                ThrowException(@"BaseExecutor",@"table coloum name  can not null", nil);
            }
            if (coloumValue.length<=0) {
                coloumValue=@"";
            }
            [tempMutDic setObject:coloumValue forKey:coloumName];
        }
        [resultDataMutArray addObject:tempMutDic];
    }
    return resultDataMutArray;
}






-(id )resultDataTypeNSObjectWithNSDictionary:(NSDictionary *)dic  resultType:(NSString *)resultTypeStr
{
    
    
    if (dic==nil) {
        return nil;
    }
    Class class=NSClassFromString(resultTypeStr);
    
    if (class==nil) {
        NSString *reason=[NSString stringWithFormat:@"%@ can not find ",resultTypeStr];
        ThrowException(@"BaseExecutor",reason, nil);
    }
    
    id object=[[class alloc]init];
    if (object==nil) {
        NSString *reason=[NSString stringWithFormat:@"%@ can not find ",resultTypeStr];
        ThrowException(@"BaseExecutor",reason, nil);
    }
    
    // [resultDataMutArray addObject:object];
    
    NSDictionary *propertyAndTypeDic=[[CacheClassProperty sharedInstance].classImpDic objectForKey:resultTypeStr];
    if (propertyAndTypeDic==nil) {
        if ([CacheClassProperty sharedInstance].classImpDic==nil) {
            [CacheClassProperty sharedInstance].classImpDic=[NSMutableDictionary dictionaryWithCapacity:0];
        }
        propertyAndTypeDic=[MyBatisUtilies getPropertyClassTypeAndName:resultTypeStr];
        [[CacheClassProperty sharedInstance].classImpDic setObject:propertyAndTypeDic forKey:resultTypeStr];
    }
    
    if (propertyAndTypeDic.count==0) {
        
    }else
    {
        
        NSArray *objectPropertyNameArray=propertyAndTypeDic.allKeys;
        
        for ( NSString *propertyName in objectPropertyNameArray) {
            
                id tempValue=[dic objectForKey:propertyName];
                NSString *lowType=[propertyAndTypeDic objectForKey:propertyName];
                // NSString *lowType=type.lowercaseString;
                if ([lowType isEqualToString:@"i"]||[lowType isEqualToString:@"d"]||[lowType isEqualToString:@"f"]) {
                    if ([tempValue isKindOfClass:[NSNumber class]]) {
                        [object setValue:tempValue forKey:propertyName];
                    }else
                    {
                        if (tempValue==nil) {
                          [object setValue:[NSNumber numberWithLongLong:0.0000000000000000000000001] forKey:propertyName];
                        }else
                        {
                            NSNumber *resultNumber=[[CacheClassProperty sharedInstance].numberFormatter numberFromString:tempValue];
                            if (resultNumber==nil) {
                                NSString *reason=[NSString stringWithFormat:@"%@ propery %@ need NSNumber type but convert fail ",resultTypeStr,propertyName];
                                ThrowException(@"BaseExecutor",reason, nil);
                            }
                            [object setValue:resultNumber forKey:propertyName];
                        }
                    }
                    
                    
                }else  if ([lowType isEqualToString:@"@\"NSString\""])
                {
                    if ([tempValue isKindOfClass:[NSString class]]) {
                        [object setValue:tempValue forKey:propertyName];
                    }else
                    {
                        [object setValue:[tempValue stringValue] forKey:propertyName];
                    }
                    
                }
        }
    }
    
    
    return object;
}


//获取resultMap
-(id )resultDataMapNSObjectWithNSDictionaryArrayAndMapDic:(NSDictionary *)dic  resultType:(NSString *)resultTypeStr mapDic:(NSDictionary *)mapDic
{
    
 
    if (dic==nil) {
        return nil;
    }
    Class class=NSClassFromString(resultTypeStr);
   
    if (class==nil) {
        NSString *reason=[NSString stringWithFormat:@"%@ can not find ",resultTypeStr];
        ThrowException(@"BaseExecutor",reason, nil);
    }
   // NSMutableArray *resultDataMutArray=[NSMutableArray arrayWithCapacity:0];
    
   // NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
   
//    NSMutableDictionary *propertyAndTypeDic=[MyBatisUtilies getPropertyClassTypeAndName:resultTypeStr];
//   
//    NSArray *columnArray=nil;
//    NSArray *objectPropertyNameArray=propertyAndTypeDic.allKeys;
//    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
//    NSDictionary *firstDic=[resultArray firstObject];
//    columnArray=firstDic.allKeys;
    
   // NSDictionary *dic=[resultArray firstObject];
    
        id object=[[class alloc]init];
        if (object==nil) {
            NSString *reason=[NSString stringWithFormat:@"%@ can not find ",resultTypeStr];
            ThrowException(@"BaseExecutor",reason, nil);
        }
    
       // [resultDataMutArray addObject:object];
    
        NSDictionary *propertyAndTypeDic=[[CacheClassProperty sharedInstance].classImpDic objectForKey:resultTypeStr];
        if (propertyAndTypeDic==nil) {
            if ([CacheClassProperty sharedInstance].classImpDic==nil) {
                [CacheClassProperty sharedInstance].classImpDic=[NSMutableDictionary dictionaryWithCapacity:0];
            }
           propertyAndTypeDic=[MyBatisUtilies getPropertyClassTypeAndName:resultTypeStr];
            [[CacheClassProperty sharedInstance].classImpDic setObject:propertyAndTypeDic forKey:resultTypeStr];
        }
    
        if (propertyAndTypeDic.count==0) {
           
        }else
        {
           
            NSArray *objectPropertyNameArray=propertyAndTypeDic.allKeys;
            
            for ( NSString *propertyName in objectPropertyNameArray) {
                
                NSString *coloum=[mapDic objectForKey:propertyName];
                
                if (coloum.length>0) {
                    id tempValue=[dic objectForKey:coloum];
                    NSString *lowType=[propertyAndTypeDic objectForKey:propertyName];
                   // NSString *lowType=type.lowercaseString;
                    if ([lowType isEqualToString:@"i"]||[lowType isEqualToString:@"d"]||[lowType isEqualToString:@"f"]) {
                        if ([tempValue isKindOfClass:[NSNumber class]]) {
                            [object setValue:tempValue forKey:propertyName];
                        }else
                        {
                            NSNumber *resultNumber=[[CacheClassProperty sharedInstance].numberFormatter numberFromString:tempValue];
                            if (resultNumber==nil) {
                                NSString *reason=[NSString stringWithFormat:@"%@ propery %@ need NSNumber type but convert fail ",resultTypeStr,propertyName];
                                ThrowException(@"BaseExecutor",reason, nil);
                            }
                            [object setValue:resultNumber forKey:propertyName];
                            
                        }
                        
                        
                    }else  if ([lowType isEqualToString:@"@\"NSString\""])
                    {
                        if ([tempValue isKindOfClass:[NSString class]]) {
                             [object setValue:tempValue forKey:propertyName];
                        }else
                        {
                            [object setValue:[tempValue stringValue] forKey:propertyName];
                        }
                       
                    }else
                    {
                        ThrowException(@"BaseExecutor",@"cannot be identified type", nil);
                    }
                }else
                {
                    [object setValue:nil forKey:propertyName];
                }
            }
    }
    

    return object;
}
-(NSMutableArray *)resultDataTypeNSObject:(FMResultSet *)set object:(id)resultObject resultType:(NSString *)resultTypeStr coloumCount:(int)coloumCount
{
    NSMutableArray *resultDataMutArray=[NSMutableArray arrayWithCapacity:0];
    NSMutableDictionary *propertyAndTypeDic=[MyBatisUtilies getPropertyClassTypeAndName:NSStringFromClass([resultObject class])];
    NSMutableArray *columnArray=[NSMutableArray arrayWithCapacity:0];
    NSArray *objectPropertyNameArray=propertyAndTypeDic.allKeys;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    for (int i=0; i<coloumCount; i++) {
        NSString *columnStr=[set columnNameForIndex:i];
        [columnArray addObject:columnStr];
    }
    while ([set next]) {
        id object=[[NSClassFromString(resultTypeStr) alloc]init];
        
        if (object==nil) {
            NSString *reason=[NSString stringWithFormat:@"%@ can not find ",resultTypeStr];
            ThrowException(@"BaseExecutor",reason, nil);
        }
        [resultDataMutArray addObject:object];
        if (propertyAndTypeDic.count==0) {
            
        }else
        {
            for (int i=0; i<objectPropertyNameArray.count; i++) {
                NSString *propertyName=[objectPropertyNameArray objectAtIndex:i];
                if ([columnArray containsObject:propertyName]) {
                    NSString *tempValue=[set stringForColumn:propertyName];
                    NSString *type=[propertyAndTypeDic objectForKey:propertyName];
                    NSString *lowType=type.lowercaseString;
                    if ([lowType isEqualToString:@"i"]||[lowType isEqualToString:@"d"]||[lowType isEqualToString:@"f"]) {
                        
                        NSNumber *resultNumber=[numberFormatter numberFromString:tempValue];
                        if (resultNumber==nil) {
                            NSString *reason=[NSString stringWithFormat:@"%@ propery %@ need NSNumber type but convert fail ",resultTypeStr,propertyName];
                            ThrowException(@"BaseExecutor",reason, nil);
                        }
                    }
                    [object setValue:tempValue forKey:propertyName];
                }else
                {
                    [object setValue:@"" forKey:propertyName];
                }
            }
        }
    }
    return resultDataMutArray;
}

-(BOOL)isClosed
{
    return NO;
}
-(void) close:(BOOL) forceRollback
{
    
}
@end
