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
 



*/

#import "BaseExecutor.h"
#import "MybatisCommonMacros.h"
#import "FMDB.h"
#import "MyBatisUtilies.h"
#import "AssociationStatement.h"
#import "CollectionStatement.h"
#import <objc/runtime.h>
@implementation BaseExecutor
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
    
    __block id resultObject=nil;
    NSString *resultStr=[self disposeSql:ms parameter:parameter];
    NSLog(@"执行sql===%@",resultStr);
    __block NSMutableArray *resultDataMutArray=nil;
    [self.configuration.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet*set=[db executeQuery:resultStr];
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
                if ([resultTypeStr.lowercaseString isEqualToString:@"map"]) {
                    resultObject=[NSMutableDictionary dictionaryWithCapacity:0];
                }else
                if ([resultTypeStr.lowercaseString isEqualToString:@"int"]) {
                    resultObject=[NSNumber numberWithInt:0];
                }else
                if ([resultTypeStr.lowercaseString isEqualToString:@"float"]) {
                    resultObject=[NSNumber numberWithFloat:0.0];
                }else
                if ([resultTypeStr.lowercaseString isEqualToString:@"double"]) {
                    resultObject=[NSNumber numberWithDouble:0.0];
                }
                else
                {
                    Class objectClass=NSClassFromString(resultTypeStr);
                    if (objectClass==nil) {
                        [set close];
                        NSString *reason=[NSString stringWithFormat:@"%@ can't identify",resultTypeStr];
                        ThrowException(@"BaseExecutor",reason, nil);
                    }
                    id object=[[objectClass alloc]init];
                    resultObject=object;
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
            resultObject=[[NSObject alloc]init];
            
        }
        
        int coloumCount=[set columnCount];
        if (coloumCount<=0) {
            [set close];
            ThrowException(@"BaseExecutor",@"expect one or more column but zero", nil);
        }
        if ([resultObject isKindOfClass:[NSNumber class]]) {
            resultDataMutArray=[self resultDataTypeNSNumber:set coloumCount:coloumCount];
            [set close];
        }else
            if ([resultObject isKindOfClass:[NSDictionary class]]) {
                resultDataMutArray=[self resultDataTypeNSDictionary:set coloumCount:coloumCount];
                [set close];
            }else
            if ([resultObject isKindOfClass:[NSObject class]]) {
                if (resultMapStatement==nil) {
                    resultDataMutArray=[self resultDataTypeNSObject:set object:resultObject resultType:resultTypeStr coloumCount:coloumCount];
                }else
                {
                     resultDataMutArray=[self resultDataTypeNSObjectWithSet:resultMapStatement sourceSet:set];
                    
//                    NSArray *tempArray=[self resultDataTypeNSDictionary:set coloumCount:coloumCount];
//                    if (resultMapStatement.associationStatementDic.allKeys.count>0||resultMapStatement.collectionStatementDic.allKeys.count>0) {
//                       // resultDataMutArray=[self resultDataTypeNSObjectAndAssociation:resultMapStatement sourceArray:tempArray];
//                        resultDataMutArray=[self resultDataTypeNSObjectWithSet:resultMapStatement sourceSet:set];
//                    }else
//                    {
//                        NSArray *convertArray=[self covertResultMapType:resultMapStatement sourceArray:tempArray];
//                        resultDataMutArray=[self resultDataTypeNSObjectWithNSDictionaryArray:convertArray  resultType:resultMapStatement.resultMapType];
//                    }
                }
            
                [set close];
            }
    }];
    return resultDataMutArray;
}


-(NSMutableArray *)resultDataTypeNSObjectWithSet:(ResultMapStatement *)resultMapStatement sourceSet:(FMResultSet *)sourceSet
{
    NSMutableArray *mutArray=[NSMutableArray arrayWithCapacity:0];
    NSMutableDictionary *filterRepatDic=[NSMutableDictionary dictionaryWithCapacity:0];
    while ([sourceSet next]) {
        NSDictionary *oriDic=sourceSet.resultDictionary;
        if (oriDic==nil) {
            return nil;
        }
        id parentElement=nil;
        NSDictionary *dic=[self covertSourceMapTypeWithSourceDic:resultMapStatement.resultMapDic sourceDic:oriDic];
        if (dic==nil) {
            return nil;
        }
        NSArray *converArray=[NSArray arrayWithObject:dic];
       // NSArray *converArray=[self covertResultMapType:resultMapStatement sourceArray:tempArray];
        NSArray *objectArray=[self resultDataTypeNSObjectWithNSDictionaryArray:converArray resultType:resultMapStatement.resultMapType];
        if (objectArray.count>0) {
            
            NSObject *object=[objectArray firstObject];
            NSDictionary *propertyIDDic=resultMapStatement.resultMapPropertyIdDic;
            if (propertyIDDic!=nil&&[propertyIDDic isKindOfClass:[NSDictionary class]]&&propertyIDDic.allKeys.count>0) {
                //NSString *property=[propertyIDDic objectForKey:@"property"];
                NSString *coloum=[NSString stringWithFormat:@"%@",[propertyIDDic objectForKey:@"property"]];
                NSString *propertyID=[NSString stringWithFormat:@"%@",[dic valueForKey:coloum]];
                if (propertyID.length<=0) {
                    propertyID=@"";
                }
                id repeatObject=[filterRepatDic objectForKey:propertyID];
                if (repeatObject!=nil) {
                    parentElement=repeatObject;
                }else
                {
                    parentElement=object;
                    [mutArray addObject:object];
                    [filterRepatDic setObject:object forKey:propertyID];
                }
            }else
            {
                parentElement=object;
                [mutArray addObject:object];
                
            }
            
            
        }
        if (parentElement==nil) {
            continue;
        }
        NSArray *tempArray=[NSArray arrayWithObject:oriDic];
        NSDictionary *assoDic=resultMapStatement.associationStatementDic;
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
        //NSDate* tmpStartData = [NSDate date];
        [self setValueRecurrence:assoDic parentObject:parentElement sourceArray:tempArray];
        [self setValueCollectionRecurrence:resultMapStatement.collectionStatementDic parentObject:parentElement sourceArray:tempArray];
//        double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
//        NSLog(@"cost time = %f", deltaTime);

    }
    [filterRepatDic removeAllObjects];
    filterRepatDic=nil;
    return mutArray;
}





//废弃
-(NSMutableArray *)resultDataTypeNSObjectAndAssociation:(ResultMapStatement *)resultMapStatement sourceArray:(NSArray *)sourceArray
{
    NSMutableArray *mutArray=[NSMutableArray arrayWithCapacity:0];
    NSMutableDictionary *filterRepatDic=[NSMutableDictionary dictionaryWithCapacity:0];
    for (int i=0; i<sourceArray.count; i++) {
        id parentElement=nil;
        NSDictionary *dic=[sourceArray objectAtIndex:i];
        NSArray *tempArray=[NSArray arrayWithObject:dic];
        NSArray *converArray=[self covertResultMapType:resultMapStatement sourceArray:tempArray];
        NSArray *objectArray=[self resultDataTypeNSObjectWithNSDictionaryArray:converArray resultType:resultMapStatement.resultMapType];
        if (objectArray.count>0) {
            
            NSObject *object=[objectArray firstObject];
            NSDictionary *propertyIDDic=resultMapStatement.resultMapPropertyIdDic;
            if (propertyIDDic!=nil&&[propertyIDDic isKindOfClass:[NSDictionary class]]&&propertyIDDic.allKeys.count>0) {
                //NSString *property=[propertyIDDic objectForKey:@"property"];
                NSString *coloum=[propertyIDDic objectForKey:@"column"];
                NSString *propertyID=[dic valueForKey:coloum];
                if (propertyID.length<=0) {
                    propertyID=@"";
                }
                id repeatObject=[filterRepatDic objectForKey:propertyID];
                if (repeatObject!=nil) {
                    parentElement=repeatObject;
                }else
                {
                    parentElement=object;
                   [mutArray addObject:object];
                    [filterRepatDic setObject:object forKey:propertyID];
                }
            }else
            {
                parentElement=object;
                [mutArray addObject:object];
                
            }
            
            
        }
        if (parentElement==nil) {
            continue;
        }
        
        NSDictionary *assoDic=resultMapStatement.associationStatementDic;
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
        [self setValueRecurrence:assoDic parentObject:parentElement sourceArray:converArray];
        [self setValueCollectionRecurrence:resultMapStatement.collectionStatementDic parentObject:parentElement sourceArray:converArray];
        
    }
    
    return mutArray;
}
-(void)setValueRecurrence:(NSDictionary *)assoDic parentObject:(id)parentObject sourceArray:(NSArray *)converArray 
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
                NSArray *assoConverArray=[self covertSourceMapType:associationStatement.associatioDic sourceArray:converArray];
                NSArray *coverObjectArray=[self resultDataTypeNSObjectWithNSDictionaryArray:assoConverArray resultType:associationStatement.associationType];
                if (coverObjectArray.count>0) {
                    NSString *type=[propertyDic objectForKey:associationStatement.associationProperty];
                    if ([type caseInsensitiveCompare:[NSString stringWithFormat:@"%@",associationStatement.associationType]]) {
                        id obj=[coverObjectArray firstObject];
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

                        [self setValueRecurrence:associationStatement.associatioDataDic parentObject:parentElement sourceArray:converArray];
                        [self setValueCollectionRecurrence:associationStatement.collectionDataDic parentObject:parentElement sourceArray:converArray];
                    }
                }else
                {
                    [parentObject setObject:nil forKey:associationStatement.associationProperty];
                }
                
                
            }
            
        }
    }
}
-(void)setValueCollectionRecurrence:(NSDictionary *)assoDic parentObject:(id)parentObject sourceArray:(NSArray *)converArray
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
                NSArray *assoConverArray=[self covertSourceMapType:associationStatement.collectionDic sourceArray:converArray];
                NSArray *coverObjectArray=[self resultDataTypeNSObjectWithNSDictionaryArray:assoConverArray resultType:associationStatement.collectionType];
                if (coverObjectArray.count>0) {
                    NSString *type=[propertyDic objectForKey:associationStatement.collectionProperty];
                    if ([type caseInsensitiveCompare:[NSString stringWithFormat:@"%@",@"NSMutableArray"]]||[type caseInsensitiveCompare:[NSString stringWithFormat:@"%@",@"NSArray"]]==NSOrderedSame) {
                        id obj=[coverObjectArray firstObject];
                        NSMutableArray *mutA=[parentObject valueForKey:associationStatement.collectionProperty];
                        if (mutA==nil||![mutA isKindOfClass:[NSArray class]]) {
                            mutA=[NSMutableArray arrayWithCapacity:0];
                        }
                        if (obj!=nil) {
                            
                            
                            
                            NSDictionary *propertyIDDic=associationStatement.collectionPropertyIdDic;
                            if (propertyIDDic!=nil&&[propertyIDDic isKindOfClass:[NSDictionary class]]&&propertyIDDic.allKeys.count>0) {
                                NSString *property=[propertyIDDic objectForKey:@"property"];
                                // NSString *coloum=[propertyIDDic objectForKey:@"column"];
                                id value=[obj valueForKey:property];
                                
                                NSString *propertyID=[NSString stringWithFormat:@"%@",value];
                                //[[obj valueForKey:property]stringValue];
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
                                    [mutA addObject:obj];
                                    [parentObject setValue:mutA forKey:associationStatement.collectionProperty];
                                }
                                
                            }else
                            {
                                parentElement=obj;
                                [mutA addObject:obj];
                                [parentObject setValue:mutA forKey:associationStatement.collectionProperty];
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
                            [self setValueCollectionRecurrence:associationStatement.collectionDataDic parentObject:parentElement sourceArray:converArray];
                            [self setValueRecurrence:associationStatement.associatioDataDic parentObject:parentElement sourceArray:converArray];
                        }
                        
                    }else
                    {
                        NSString *reason=[NSString stringWithFormat:@"%@ collection must Array",associationStatement.collectionProperty];
                        ThrowException(@"BaseExecutor",reason, nil);
                    }
                }else
                {
                    [parentObject setValue:nil forKey:associationStatement.collectionProperty];
                    
                }
                
                
            }
            
        }
    }
}


-(NSDictionary *)covertSourceMapTypeWithSourceDic:(NSDictionary *)resultMapDic sourceDic:(NSDictionary *)sourceDic
{
        NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
        NSDictionary *tempDic=sourceDic;
        NSArray *keys=tempDic.allKeys;
        for (NSString *key in keys) {
            NSString *property=[resultMapDic objectForKey:key];
            if (property.length>0) {
                [mutDic setObject:[tempDic objectForKey:key] forKey:property];
            }else
            {
                [mutDic setObject:[tempDic objectForKey:key] forKey:key];
            }
        }
    return mutDic;
}


-(NSArray *)covertSourceMapType:(NSDictionary *)resultMapDic sourceArray:(NSArray *)sourceArray
{
    NSMutableArray *convertArray=[NSMutableArray arrayWithCapacity:0];
    
    for (int i=0; i<sourceArray.count; i++) {
        NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
        NSDictionary *tempDic=[sourceArray objectAtIndex:i];
        NSArray *keys=tempDic.allKeys;
        for (NSString *key in keys) {
            NSString *property=[resultMapDic objectForKey:key];
            if (property.length>0) {
                [mutDic setObject:[tempDic objectForKey:key] forKey:property];
            }else
            {
                [mutDic setObject:[tempDic objectForKey:key] forKey:key];
            }
        }
        [convertArray addObject:mutDic];
    }
    return convertArray;
}
-(NSArray *)covertResultMapType:(ResultMapStatement *)rs sourceArray:(NSArray *)sourceArray
{
    NSMutableDictionary *resultMapDic=rs.resultMapDic;
    return [self covertSourceMapType:resultMapDic sourceArray:sourceArray];
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










-(NSMutableArray *)resultDataTypeNSObjectWithNSDictionaryArray:(NSArray *)resultArray  resultType:(NSString *)resultTypeStr
{
    if (resultArray.count<=0) {
        return nil;
    }
    Class class=NSClassFromString(resultTypeStr);
    if (class==nil) {
        NSString *reason=[NSString stringWithFormat:@"%@ can not find ",resultTypeStr];
        ThrowException(@"BaseExecutor",reason, nil);
    }
    NSMutableArray *resultDataMutArray=[NSMutableArray arrayWithCapacity:0];
    
    NSMutableDictionary *propertyAndTypeDic=[MyBatisUtilies getPropertyClassTypeAndName:resultTypeStr];
    NSArray *columnArray=nil;
    NSArray *objectPropertyNameArray=propertyAndTypeDic.allKeys;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSDictionary *firstDic=[resultArray firstObject];
    columnArray=firstDic.allKeys;
    for (int i=0; i<resultArray.count; i++) {
        id object=[[NSClassFromString(resultTypeStr) alloc]init];
        
        if (object==nil) {
            NSString *reason=[NSString stringWithFormat:@"%@ can not find ",resultTypeStr];
            ThrowException(@"BaseExecutor",reason, nil);
        }
        [resultDataMutArray addObject:object];
        if (propertyAndTypeDic.count==0) {
            continue;
        }else
        {
            NSDictionary *dic=[resultArray objectAtIndex:i];
            for (int i=0; i<objectPropertyNameArray.count; i++) {
                NSString *propertyName=[objectPropertyNameArray objectAtIndex:i];
                if ([columnArray containsObject:propertyName]) {
                    NSString *tempValue=[NSString stringWithFormat:@"%@",[dic objectForKey:propertyName]];
                    NSString *type=[propertyAndTypeDic objectForKey:propertyName];
                    NSString *lowType=type.lowercaseString;
                    if ([lowType isEqualToString:@"i"]||[lowType isEqualToString:@"d"]||[lowType isEqualToString:@"f"]) {
                        
                        NSNumber *resultNumber=[numberFormatter numberFromString:tempValue];
                        if (resultNumber==nil) {
                            NSString *reason=[NSString stringWithFormat:@"%@ propery %@ need NSNumber type but convert fail ",resultTypeStr,propertyName];
                            ThrowException(@"BaseExecutor",reason, nil);
                        }
                        [object setValue:resultNumber forKey:propertyName];
                    }else
                    {
                        [object setValue:tempValue forKey:propertyName];
                    }
                }else
                {
                    [object setValue:nil forKey:propertyName];
                }
            }
        }
    }
    return resultDataMutArray;
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
