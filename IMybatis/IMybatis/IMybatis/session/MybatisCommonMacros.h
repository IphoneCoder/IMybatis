//
//  DSACommonMacros.h
//  YIMADSACarCopy
//
//  Created by 汪亚强 on 14-11-13.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#define ThrowException(exceptionName, exceptionReason, exceptionUserInfo)        @throw \
[NSException exceptionWithName:exceptionName reason:exceptionReason userInfo:exceptionUserInfo]

