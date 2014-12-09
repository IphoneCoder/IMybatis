//
//  XMLConfigBuilder.m
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-17.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import "XMLConfigBuilder.h"
#import "MybatisCommonMacros.h"
#import "MappedStatement.h"
#import "AssociationStatement.h"
#import "CollectionStatement.h"
#import "TBXML.h"
@implementation XMLConfigBuilder
{
    BOOL parsed;//是否解析过
    
}

@synthesize inputStream;
@synthesize configuration;
@synthesize inputData;
@synthesize parseObjectArray;
-(id)initXMLConfigBuilderWithInputStream:(NSInputStream *)_inputStream configuration:(Configuration *)_configuration
{
    self=[super init];
    if (self) {
        self.inputStream=_inputStream;
        self.configuration=_configuration;
        self.parseObjectArray=[NSMutableArray arrayWithCapacity:0];
    }
    return self;
}
-(id)initXMLConfigBuilderWithInputData:(NSData *)_inputData configuration:(Configuration *)_configuration
{
    self=[super init];
    if (self) {
        self.inputData=_inputData;
        self.configuration=_configuration;
        self.parseObjectArray=[NSMutableArray arrayWithCapacity:0];
    }
    return self;

}
-(Configuration *)parse
{
    if (self.inputStream==nil&&self.inputData==nil) {
        NSException *exception=[NSException exceptionWithName:@"XMLConfigBuilder" reason:@"inputStream cont not nil" userInfo:nil];
        @throw exception;
    }
    
    if (parsed) {
         //BuilderException("Each XMLConfigBuilder can only be used once.")
       // DDLogError(@"Each XMLConfigBuilder can only be used once.");
        NSException *exception=[NSException exceptionWithName:@"XMLConfigBuilder" reason:@"Each XMLConfigBuilder can only be used once." userInfo:nil];
        @throw exception;
    }
    NSError *error=nil;
    TBXML *tbxml=[TBXML newTBXMLWithXMLData:self.inputData error:&error];
    if (error!=nil) {
        NSException *exception=[NSException exceptionWithName:@"XMLConfigBuilder" reason:[NSString stringWithFormat:@"%@",error] userInfo:nil];
        @throw exception;
    }
    [self parseConfiguration:tbxml.rootXMLElement];
    return nil;
}
-(void)parseConfiguration:(TBXMLElement *)rootElement
{
    [self dataSourceElement:[TBXML childElementNamed:@"dataSource" parentElement:rootElement]];
    [self mappersElement:[TBXML childElementNamed:@"mappers" parentElement:rootElement]];
    //[self dataSourceElement:];
}
-(void)dataSourceElement:(TBXMLElement *)parent
{
    [TBXML iterateElementsForQuery:@"property" fromElement:parent withBlock:^(TBXMLElement *element) {
        
        [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
            if ([attributeName.lowercaseString isEqualToString:@"name"]) {
                if (attributeValue.length<=0) {
                    NSException *exception=[NSException exceptionWithName:@"XMLConfigBuilder" reason:@"databasename node can not null" userInfo:nil];
                    @throw exception;
                }
            }else
                if ([attributeName.lowercaseString isEqualToString:@"value"]) {
                    if (attributeValue.length<=0) {
                        NSException *exception=[NSException exceptionWithName:@"XMLConfigBuilder" reason:@"databasename can not null" userInfo:nil];
                        @throw exception;
                    }
                    self.configuration.databasename=attributeValue;
                    if (self.configuration.databaseQueue.openFlags!=100) {
                        NSBundle *bundle=[NSBundle bundleForClass:[self class]];
                        
                        NSString *path=[bundle pathForAuxiliaryExecutable:self.configuration.databasename];//[[NSBundle mainBundle]pathForResource:@"DSADB" ofType:@"db"];
                        self.configuration.databaseQueue=[FMDatabaseQueue databaseQueueWithPath:path];
                        self.configuration.databasePath=path;
                    }

                }
            if (self.configuration.otherInfoArray==nil) {
                self.configuration.otherInfoArray=[NSMutableArray arrayWithArray:0];
            }
            if (attributeName.length>0&&attributeValue.length>0) {
                NSDictionary *dic=[NSDictionary dictionaryWithObject:attributeValue forKey:attributeName];
                [self.configuration.otherInfoArray addObject:dic];//这里是否要考虑key重复的情况
            }
           
        }];
        
    }];
}
-(void)mappersElement:(TBXMLElement *)parent
{
    [TBXML iterateElementsForQuery:@"mapper" fromElement:parent withBlock:^(TBXMLElement *element) {
        [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
            if ([attributeName.lowercaseString isEqualToString:@"resource"]) {
                if (attributeValue.length>0) {
                    [self mapperFileParse:attributeValue];
                }
            }
        }];
    }];
}
-(void)mapperFileParse:(NSString *)mapperFileName
{
    if (mapperFileName.length<=0) {
        ThrowException(@"XMLConfigBuilder", @"mapper resource can not be null ", nil);
    }
    //NSString *path=[[NSBundle mainBundle]pathForAuxiliaryExecutable:mapperFileName];
     NSBundle *bundle=[NSBundle bundleForClass:[self class]];
    NSString *path=[bundle pathForAuxiliaryExecutable:mapperFileName];
   // NSString *path=@"/Users/wangyaqiang/Desktop/项目/YIMADSACarCopy4/YIMADSACarCopy/mybatis/userMapper.xml";
    NSData *data=[NSData dataWithContentsOfFile:path];
    if (data.length>0) {
        TBXML *tb=[TBXML newTBXMLWithXMLData:data error:nil];
        [self mapperElement:tb.rootXMLElement];
    }
    
   
}
-(void)mapperElement:(TBXMLElement *)rootElement
{
    __block NSString *namespace=@"";
    [TBXML iterateAttributesOfElement:rootElement withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
        if ([attributeName.lowercaseString isEqualToString:@"namespace"]) {
            namespace=attributeValue;
        }
    }];
    [self recurrence:rootElement namespace:namespace];
    NSLog(@"%@",self.configuration);
}

-(void)dealMapper:(TBXMLElement *)element namespace:(NSString *)_namespace
{
       //[self.configuration.mappedStatementArray addObject:mapperStatement];
    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSString *mapperType=[TBXML elementName:element];
    if ([mapperType caseInsensitiveCompare:@"resultMap"]==NSOrderedSame) {
        [self dealResultMap:element namespace:_namespace];
        return;
    }
    MappedStatement *mapperStatement=[[MappedStatement alloc]init];
    [self.parseObjectArray removeAllObjects];
    [self.parseObjectArray addObject:mapperStatement];
    if (self.configuration.mappedStatementDic==nil) {
        self.configuration.mappedStatementDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }

    if (mapperType.length>0) {
        [mutDic setObject:mapperType forKey:@"mapperType"];
    }
    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
        [mutDic setObject:attributeValue  forKey:attributeName];
    }];
    if ([mutDic objectForKey:@"id"]==nil) {
        NSString *reason=[NSString stringWithFormat:@"namesapce:%@ xml required id",_namespace];
        ThrowException(@"XMLConfigBuilder",reason, nil);
    }
    mapperStatement.mapperNamespace=_namespace;
    mapperStatement.mapperID=[mutDic objectForKey:@"id"];
    NSString *trueID=[NSString stringWithFormat:@"%@.%@",_namespace,mapperStatement.mapperID];
    if ([self.configuration.mappedStatementDic objectForKey:trueID]!=nil) {
        NSString *reason=[NSString stringWithFormat:@"%@ must uniqueness",trueID];
        ThrowException(@"XMLConfigBuilder",reason , nil);
    }
    mapperStatement.mapperOriAttributeDataDic=mutDic;
    mapperStatement.mapperSqlSource=[TBXML textForElement:element];
    mapperStatement.mapperParameterType=[mutDic objectForKey:@"parameterType"];
    mapperStatement.mapperResultType=[mutDic objectForKey:@"resultType"];
    mapperStatement.mapperResultMap=[mutDic objectForKey:@"resultMap"];
    [self mapperTypeConvertToEnum:mapperStatement];
    [self.configuration.mappedStatementDic setObject:mapperStatement forKey:trueID];
}
-(void)dealResultMap:(TBXMLElement *)element namespace:(NSString *)_namespace
{
    ResultMapStatement *resultMapStatement=[[ResultMapStatement alloc]init];
    [self.parseObjectArray removeAllObjects];
    [self.parseObjectArray addObject: resultMapStatement];
    //self.parseObject=resultMapStatement;
    if (self.configuration.resultMapStatementDic==nil) {
        self.configuration.resultMapStatementDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }
    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
        [mutDic setObject:attributeValue  forKey:attributeName];
    }];
    if ([mutDic objectForKey:@"id"]==nil) {
    
        NSString *reason=[NSString stringWithFormat:@"namesapce:%@ xml required id",_namespace];
        ThrowException(@"XMLConfigBuilder",reason, nil);
    }
    resultMapStatement.resultMapNameSpace=_namespace;
    resultMapStatement.resultMapId=[mutDic objectForKey:@"id"];
    NSString *trueID=[NSString stringWithFormat:@"%@.%@",_namespace,resultMapStatement.resultMapId];
    if ([self.configuration.mappedStatementDic objectForKey:trueID]!=nil) {
    
        NSString *reason=[NSString stringWithFormat:@"%@ must uniqueness",trueID];
        ThrowException(@"XMLConfigBuilder",reason , nil);
    }
    resultMapStatement.resultMapType=[mutDic objectForKey:@"type"];
    if (resultMapStatement.resultMapType.length<=0) {
        
        NSString *reason=[NSString stringWithFormat:@"%@ type must have value",trueID];
        ThrowException(@"XMLConfigBuilder",reason , nil);
    }
    resultMapStatement.resultMapAttributeDataDic=mutDic;
    [self.configuration.resultMapStatementDic setObject:resultMapStatement forKey:trueID];
}
-(void)dealAssociationStatement:(TBXMLElement *)element resultMapStatement:(ResultMapStatement *)resultMapStatement attributeDic:(NSMutableDictionary *)mutDic
{
    if (resultMapStatement.associationStatementDic==nil) {
        resultMapStatement.associationStatementDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }
    AssociationStatement *associationStatement=[[AssociationStatement alloc]init];
    [self.parseObjectArray addObject:associationStatement];
    //self.parseObject=associationStatement;
//    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
//    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
//        [mutDic setObject:attributeValue  forKey:attributeName];
//    }];
    NSString *property=[mutDic objectForKey:@"property"];
    NSString *type=[mutDic objectForKey:@"type"];
    if (property.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required property", nil);
    }
    if (type.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required type", nil);
    }
    id obj=[resultMapStatement.associationStatementDic objectForKey:property];
    if (obj!=nil) {
        NSString *reason=[NSString stringWithFormat:@"association property %@ must uniqueness",property];
        ThrowException(@"XMLConfigBuilder",reason, nil);
    }
    associationStatement.associationProperty=property;
    associationStatement.associationType=type;
    associationStatement.associatioAttributeDataDic=mutDic;
    [resultMapStatement.associationStatementDic setObject:associationStatement forKey:property];

}


-(void)dealCollectionStatement:(TBXMLElement *)element resultMapStatement:(ResultMapStatement *)resultMapStatement attributeDic:(NSMutableDictionary *)mutDic
{
    if (resultMapStatement.collectionStatementDic==nil) {
        resultMapStatement.collectionStatementDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }
    CollectionStatement *associationStatement=[[CollectionStatement alloc]init];
    [self.parseObjectArray addObject:associationStatement];
    //self.parseObject=associationStatement;
    //    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
    //    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
    //        [mutDic setObject:attributeValue  forKey:attributeName];
    //    }];
    NSString *property=[mutDic objectForKey:@"property"];
    NSString *type=[mutDic objectForKey:@"type"];
    if (property.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required property", nil);
    }
    if (type.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required type", nil);
    }
    id obj=[resultMapStatement.associationStatementDic objectForKey:property];
    if (obj!=nil) {
        NSString *reason=[NSString stringWithFormat:@"association property %@ must uniqueness",property];
        ThrowException(@"XMLConfigBuilder",reason, nil);
    }
    associationStatement.collectionProperty=property;
    associationStatement.collectionType=type;
    associationStatement.collectionAttributeDataDic=mutDic;
    [resultMapStatement.collectionStatementDic setObject:associationStatement forKey:property];
    
}


-(void)dealAssociationStatementWithCollectionStatement:(TBXMLElement *)element parentAssociationStatement:(AssociationStatement *)parentAssociationStatement attributeDic:(NSMutableDictionary *)mutDic
{
    CollectionStatement *associationStatement=[[CollectionStatement alloc]init];
    [self.parseObjectArray addObject:associationStatement];
    //self.parseObject=associationStatement;
    //    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
    //    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
    //        [mutDic setObject:attributeValue  forKey:attributeName];
    //    }];
    NSString *property=[mutDic objectForKey:@"property"];
    NSString *type=[mutDic objectForKey:@"type"];
    if (property.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required property", nil);
    }
    if (type.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required type", nil);
    }
    associationStatement.collectionProperty=property;
    associationStatement.collectionType=type;
    associationStatement.collectionAttributeDataDic=mutDic;
    if (parentAssociationStatement.collectionDataDic==nil) {
        parentAssociationStatement.collectionDataDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }
    [parentAssociationStatement.collectionDataDic setObject:associationStatement forKey:property];
}



-(void)dealCollectionStatementWithAssociationStatement:(TBXMLElement *)element parentAssociationStatement:(CollectionStatement *)parentCollectionStatement attributeDic:(NSMutableDictionary *)mutDic
{
    AssociationStatement *associationStatement=[[AssociationStatement alloc]init];
    [self.parseObjectArray addObject:associationStatement];
    //self.parseObject=associationStatement;
    //    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
    //    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
    //        [mutDic setObject:attributeValue  forKey:attributeName];
    //    }];
    NSString *property=[mutDic objectForKey:@"property"];
    NSString *type=[mutDic objectForKey:@"type"];
    if (property.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required property", nil);
    }
    if (type.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required type", nil);
    }
    associationStatement.associationProperty=property;
    associationStatement.associationType=type;
    associationStatement.associatioAttributeDataDic=mutDic;
    if (parentCollectionStatement.associatioDataDic==nil) {
        parentCollectionStatement.associatioDataDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }
    [parentCollectionStatement.associatioDataDic setObject:associationStatement forKey:property];
}


-(void)dealAssociationStatementWithAssociationStatement:(TBXMLElement *)element associationStatement:(AssociationStatement *)parentAssociationStatement attributeDic:(NSMutableDictionary *)mutDic
{
    
    AssociationStatement *associationStatement=[[AssociationStatement alloc]init];
    [self.parseObjectArray addObject:associationStatement];
    //self.parseObject=associationStatement;
    //    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
    //    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
    //        [mutDic setObject:attributeValue  forKey:attributeName];
    //    }];
    NSString *property=[mutDic objectForKey:@"property"];
    NSString *type=[mutDic objectForKey:@"type"];
    if (property.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required property", nil);
    }
    if (type.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required type", nil);
    }
    associationStatement.associationProperty=property;
    associationStatement.associationType=type;
    associationStatement.associatioAttributeDataDic=mutDic;
    if (parentAssociationStatement.associatioDataDic==nil) {
        parentAssociationStatement.associatioDataDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }
    [parentAssociationStatement.associatioDataDic setObject:associationStatement forKey:property];
    
}
-(void)dealCollectionStatementWithParentCollectionStatement:(TBXMLElement *)element collectionStatement:(CollectionStatement *)parentCollectionStatement attributeDic:(NSMutableDictionary *)mutDic
{
    
    CollectionStatement *associationStatement=[[CollectionStatement alloc]init];
    [self.parseObjectArray addObject:associationStatement];
    //self.parseObject=associationStatement;
    //    NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
    //    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
    //        [mutDic setObject:attributeValue  forKey:attributeName];
    //    }];
    NSString *property=[mutDic objectForKey:@"property"];
    NSString *type=[mutDic objectForKey:@"type"];
    if (property.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required property", nil);
    }
    if (type.length<=0) {
        ThrowException(@"XMLConfigBuilder",@"association  required type", nil);
    }
    associationStatement.collectionProperty=property;
    associationStatement.collectionType=type;
    associationStatement.collectionAttributeDataDic=mutDic;
    if (parentCollectionStatement.collectionDataDic==nil) {
        parentCollectionStatement.collectionDataDic=[NSMutableDictionary dictionaryWithCapacity:0];
    }
    [parentCollectionStatement.collectionDataDic setObject:associationStatement forKey:property];
    
}

- (void)recurrence:(TBXMLElement *)element namespace:(NSString *)_namespace {
    do {
        TBXMLElement *parentElement=element->parentElement;
        if (parentElement!=nil) {
            NSLog(@"=======%@=========%@",[TBXML elementName:parentElement],[TBXML elementName:element]);
        }
        
        if (parentElement!=nil&&[[TBXML elementName:parentElement] isEqualToString:@"mapper"]) {
            
            [self dealMapper:element namespace:_namespace];
        }else if (parentElement!=nil&&[[TBXML elementName:parentElement] isEqualToString:@"resultMap"])
        {
            NSString *elementName=[TBXML elementName:element];
          
            NSString *PID=[TBXML valueOfAttributeNamed:@"id" forElement:parentElement];
            NSString *trueID=[NSString stringWithFormat:@"%@.%@",_namespace,PID];
            ResultMapStatement *resultMapStatement=[self.configuration.resultMapStatementDic objectForKey:trueID];

            NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
            [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
                if (attributeName.length<=0) {
                     ThrowException(@"XMLConfigBuilder",@"resultMap attributeName can not null", nil);
                }
                if (attributeValue.length<=0) {
                    attributeValue=@"";
                }
                [mutDic setObject:attributeValue forKey:attributeName];
            }];
            if ([elementName caseInsensitiveCompare:@"association"]==NSOrderedSame) {
                [self dealAssociationStatement:element resultMapStatement:resultMapStatement attributeDic:mutDic];
                
            }else if ([elementName caseInsensitiveCompare:@"collection"]==NSOrderedSame) {
                
                [self dealCollectionStatement:element resultMapStatement:resultMapStatement attributeDic:mutDic];
                //[self dealAssociationStatement:element resultMapStatement:resultMapStatement attributeDic:mutDic];
                
            }else{
                if (resultMapStatement.resultMapArray==nil) {
                    resultMapStatement.resultMapArray=[NSMutableArray arrayWithCapacity:0];
                }
                if (resultMapStatement.resultMapReversalDic==nil) {
                    resultMapStatement.resultMapReversalDic=[NSMutableDictionary dictionaryWithCapacity:0];
                }
                if (resultMapStatement.resultMapDic==nil) {
                    resultMapStatement.resultMapDic=[NSMutableDictionary dictionaryWithCapacity:0];
                }
                if (mutDic!=nil) {
                    [resultMapStatement.resultMapArray addObject:mutDic];
                    NSString *property=[mutDic objectForKey:@"property"];
                    NSString *column=[mutDic objectForKey:@"column"];
                    if (property.length<=0||column.length<=0) {
                        ThrowException(@"XMLConfigBuilder",@"property and column can not null", nil);
                    }
                    
                    if ([elementName caseInsensitiveCompare:@"id"]==NSOrderedSame) {
                        if (resultMapStatement.resultMapPropertyIdDic!=nil) {
                            ThrowException(@"XMLConfigBuilder",@"only have one id property", nil);

                        }
                        resultMapStatement.resultMapPropertyIdDic=[NSMutableDictionary dictionaryWithDictionary:mutDic];
                    }
                    NSDictionary *dic=[NSDictionary dictionaryWithObject:[mutDic objectForKey:@"property"] forKey:[mutDic objectForKey:@"column"]];
                     NSDictionary *reverDic=[NSDictionary dictionaryWithObject:[mutDic objectForKey:@"column"] forKey:[mutDic objectForKey:@"property"]];
                    [resultMapStatement.resultMapDic addEntriesFromDictionary:dic];
                    [resultMapStatement.resultMapReversalDic addEntriesFromDictionary:reverDic];
                }
            }
            
        }else if (parentElement!=nil&&[[TBXML elementName:parentElement] caseInsensitiveCompare:@"association"]==NSOrderedSame)
        {
            
            NSString *elementName=[TBXML elementName:element];
           
            NSString *PProperty=[TBXML valueOfAttributeNamed:@"property" forElement:parentElement];
            NSObject *parseObject=[self.parseObjectArray lastObject];
            AssociationStatement *associationStatement=nil;
            if ([parseObject isKindOfClass:[AssociationStatement class]]) {
        
               AssociationStatement * tempAssociationStatement=(AssociationStatement *)parseObject;
                if ([tempAssociationStatement.associationProperty isEqualToString:PProperty]) {
                    associationStatement=tempAssociationStatement;
                }else
                {
                    [self.parseObjectArray removeLastObject];
                    parseObject=[self.parseObjectArray lastObject];
                    if ([parseObject isKindOfClass:[AssociationStatement class]]) {
                         associationStatement=(AssociationStatement *)parseObject;
                    }
                }
                
            }
           
            if (associationStatement==nil) {
                ThrowException(@"XMLConfigBuilder",@"parse error", nil);
            }
            if (associationStatement.associatioArray==nil) {
                associationStatement.associatioArray=[NSMutableArray arrayWithCapacity:0];
            }
            if (associationStatement.associatioDic==nil) {
                associationStatement.associatioDic=[NSMutableDictionary dictionaryWithCapacity:0];
            }
            if (associationStatement.associatioReversalDic==nil) {
                associationStatement.associatioReversalDic=[NSMutableDictionary dictionaryWithCapacity:0];
            }
            NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
            [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
                if (attributeName.length<=0) {
                    ThrowException(@"XMLConfigBuilder",@"resultMap attributeName can not null", nil);
                }
                if (attributeValue.length<=0) {
                    attributeValue=@"";
                }
                [mutDic setObject:attributeValue forKey:attributeName];
            }];
            if (mutDic!=nil) {
                if ([elementName caseInsensitiveCompare:@"association"]==NSOrderedSame) {
                    [self dealAssociationStatementWithAssociationStatement:element associationStatement:associationStatement attributeDic:mutDic];
                    
                }else if ([elementName caseInsensitiveCompare:@"collection"]==NSOrderedSame) {
                    [self dealAssociationStatementWithCollectionStatement:element parentAssociationStatement:associationStatement attributeDic:mutDic];
                    //[self dealAssociationStatementWithAssociationStatement:element associationStatement:associationStatement attributeDic:mutDic];
                    
                }else
                {
                    [associationStatement.associatioArray addObject:mutDic];
                    if ([[TBXML elementName:element]caseInsensitiveCompare:@"id"]==NSOrderedSame) {
                        if (associationStatement.associationPropertyIdDic!=nil) {
                            ThrowException(@"XMLConfigBuilder",@"only have one id property", nil);
                        }
                        if (associationStatement.associationPropertyIdDic==nil) {
                            associationStatement.associationPropertyIdDic=[NSMutableDictionary dictionaryWithDictionary:mutDic];
                        }
                    }
                    NSString *property=[mutDic objectForKey:@"property"];
                    NSString *column=[mutDic objectForKey:@"column"];
                    if (property.length<=0||column.length<=0) {
                         ThrowException(@"XMLConfigBuilder",@"property and column can not null", nil);
                    }
                    [associationStatement.associatioDic setObject:[mutDic objectForKey:@"property"] forKey:[mutDic objectForKey:@"column"]];
                     [associationStatement.associatioReversalDic setObject:[mutDic objectForKey:@"column"] forKey:[mutDic objectForKey:@"property"]];
                }
            }

        }else if (parentElement!=nil&&[[TBXML elementName:parentElement] caseInsensitiveCompare:@"collection"]==NSOrderedSame)
        {
            
            NSString *elementName=[TBXML elementName:element];
            
            NSString *PProperty=[TBXML valueOfAttributeNamed:@"property" forElement:parentElement];
            NSObject *parseObject=[self.parseObjectArray lastObject];
            CollectionStatement *associationStatement=nil;
            if ([parseObject isKindOfClass:[CollectionStatement class]]) {
                
                CollectionStatement * tempAssociationStatement=(CollectionStatement *)parseObject;
                if ([tempAssociationStatement.collectionProperty isEqualToString:PProperty]) {
                    associationStatement=tempAssociationStatement;
                }else
                {
                    [self.parseObjectArray removeLastObject];
                    parseObject=[self.parseObjectArray lastObject];
                    if ([parseObject isKindOfClass:[CollectionStatement class]]) {
                        associationStatement=(CollectionStatement *)parseObject;
                    }
                }
                
            }
            
            if (associationStatement==nil) {
                ThrowException(@"XMLConfigBuilder",@"parse error", nil);
            }
            if (associationStatement.collectionArray==nil) {
                associationStatement.collectionArray=[NSMutableArray arrayWithCapacity:0];
            }
            if (associationStatement.collectionDic==nil) {
                associationStatement.collectionDic=[NSMutableDictionary dictionaryWithCapacity:0];
            }
            if (associationStatement.collectionReversalDic==nil) {
                associationStatement.collectionReversalDic=[NSMutableDictionary dictionaryWithCapacity:0];
            }
            NSMutableDictionary *mutDic=[NSMutableDictionary dictionaryWithCapacity:0];
            [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
                if (attributeName.length<=0) {
                    ThrowException(@"XMLConfigBuilder",@"resultMap attributeName can not null", nil);
                }
                if (attributeValue.length<=0) {
                    attributeValue=@"";
                }
                [mutDic setObject:attributeValue forKey:attributeName];
            }];
            if (mutDic!=nil) {
                if ([elementName caseInsensitiveCompare:@"association"]==NSOrderedSame) {
                    //[self dealAssociationStatementWithAssociationStatement:element associationStatement:associationStatement attributeDic:mutDic];
                    [self dealCollectionStatementWithAssociationStatement:element parentAssociationStatement:associationStatement attributeDic:mutDic];
                    
                }else if ([elementName caseInsensitiveCompare:@"collection"]==NSOrderedSame) {
                    //[self dealAssociationStatementWithCollectionStatement:element parentAssociationStatement:associationStatement attributeDic:mutDic];
                    //[self dealAssociationStatementWithAssociationStatement:element associationStatement:associationStatement attributeDic:mutDic];
                    [self dealCollectionStatementWithParentCollectionStatement:element collectionStatement:associationStatement attributeDic:mutDic];
                    
                }else
                {
                    [associationStatement.collectionArray addObject:mutDic];
                    if ([[TBXML elementName:element]caseInsensitiveCompare:@"id"]==NSOrderedSame) {
                        if (associationStatement.collectionPropertyIdDic!=nil) {
                            ThrowException(@"XMLConfigBuilder",@"only have one id property", nil);
                        }
                        if (associationStatement.collectionPropertyIdDic==nil) {
                            associationStatement.collectionPropertyIdDic=[NSMutableDictionary dictionaryWithDictionary:mutDic];
                        }
                    }
                    NSString *property=[mutDic objectForKey:@"property"];
                    NSString *column=[mutDic objectForKey:@"column"];
                    if (property.length<=0||column.length<=0) {
                        ThrowException(@"XMLConfigBuilder",@"property and column can not null", nil);
                    }
                   // NSDictionary *dic=[NSDictionary dictionaryWithObject:[mutDic objectForKey:@"property"] forKey:[mutDic objectForKey:@"column"]];
                    [associationStatement.collectionDic setObject:[mutDic objectForKey:@"property"] forKey:[mutDic objectForKey:@"column"]];
                    [associationStatement.collectionReversalDic setObject:[mutDic objectForKey:@"column"] forKey:[mutDic objectForKey:@"property"]];
                }
            }
            
        }
                //迭代处理所有属性
        TBXMLAttribute * attribute = element->firstAttribute;
        while (attribute) {
            attribute = attribute->next;
        }
        
        //递归处理子树
        if (element->firstChild) {
            [self recurrence:element->firstChild namespace:_namespace];
        }
        
        //迭代处理兄弟树
    } while ((element = element->nextSibling));
    NSLog(@"%@",configuration);
}
-(void)mapperTypeConvertToEnum:(MappedStatement *)ms
{
    NSString *mapperTypeStr=[ms.mapperOriAttributeDataDic objectForKey:@"mapperType"];
    if ([mapperTypeStr.lowercaseString isEqualToString:@"select"]) {
        ms.mapperType=MapperTypeSelect;
    }else
    if ([mapperTypeStr.lowercaseString isEqualToString:@"update"]) {
        ms.mapperType=MapperTypeUpdate;
    }else
    if ([mapperTypeStr.lowercaseString isEqualToString:@"delete"]) {
        ms.mapperType=MapperTypeDelete;
    }else
    if ([mapperTypeStr.lowercaseString isEqualToString:@"replace"]) {
        ms.mapperType=MapperTypeReplace;
    }else
    if ([mapperTypeStr.lowercaseString isEqualToString:@"insert"]) {
            ms.mapperType=MapperTypeInsert;
    }else
    if ([mapperTypeStr.lowercaseString isEqualToString:@"resultmap"]) {
            ms.mapperType=MapperTypeResultMap;
    }
}
@end
