//
//  DSASqlSession.h
//  YIMADSACarCopy
//
//  Created by wangyaqiang on 14-11-16.
//  Copyright (c) 2014年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SqlSession <NSObject>
//语句执行方法
//这些方法被用来执行SELECT，INSERT，UPDATE和DELETE语句。
/**
 * Retrieve a single row mapped from the statement key
 * 获取一条记录
 * @param <T> the returned id type
 * @param statement
 * @return Mapped id
 */
-(id) selectOne:(NSString  *) statement;

/**
 * Retrieve a single row mapped from the statement key and parameter.
 * 获取一条记录
 * @param <T> the returned id type
 * @param statement Unique identifier matching the statement to use.
 * @param parameter A parameter id to pass to the statement.
 * @return Mapped id
 */
-(id) selectOne:(NSString *) statement parameter:(id) parameter;

/**
 * Retrieve a list of mapped ids from the statement key and parameter.
 * 获取多条记录
 * @param <E> the returned list element type
 * @param statement Unique identifier matching the statement to use.
 * @return List of mapped id
 */
-(id) selectList:(NSString *) statement;

/**
 * Retrieve a list of mapped ids from the statement key and parameter.
 * 获取多条记录
 * @param <E> the returned list element type
 * @param statement Unique identifier matching the statement to use.
 * @param parameter A parameter id to pass to the statement.
 * @return List of mapped id
 */
-(id) selectList:(NSString *) statement parameter:(id) parameter;



/**
 * The selectMap is a special case in that it is designed to convert a list
 * of results into a Map based on one of the properties in the resulting
 * ids.
 * Eg. Return a of Map[Integer,Author] for selectMap("selectAuthors","id")
 * 获取多条记录,并存入Map
 * @param <K> the returned Map keys type
 * @param <V> the returned Map values type
 * @param statement Unique identifier matching the statement to use.
 * @param mapKey The property to use as key for each value in the list.
 * @return Map containing key pair data.
 */
-(NSDictionary *) selectMap:(NSString *) statement mapKey:(NSString *) mapKey;

/**
 * The selectMap is a special case in that it is designed to convert a list
 * of results into a Map based on one of the properties in the resulting
 * ids.
 * 获取多条记录,并存入Map
 * @param <K> the returned Map keys type
 * @param <V> the returned Map values type
 * @param statement Unique identifier matching the statement to use.
 * @param parameter A parameter id to pass to the statement.
 * @param mapKey The property to use as key for each value in the list.
 * @return Map containing key pair data.
 */
-(NSDictionary *) selectMap:(NSString *) statement parameter:(id) parameter mapKey:(NSString *) mapKey;








/**
 * Execute an insert statement.
 * 插入记录
 * @param statement Unique identifier matching the statement to execute.
 * @return int The number of rows affected by the insert.
 */
-(BOOL) insert:(NSString *) statement;

/**
 * Execute an insert statement with the given parameter id. Any generated
 * autoincrement values or selectKey entries will modify the given parameter
 * id properties. Only the number of rows affected will be returned.
 * 插入记录
 * @param statement Unique identifier matching the statement to execute.
 * @param parameter A parameter id to pass to the statement.
 * @return int The number of rows affected by the insert.
 */
-(BOOL) insert:(NSString *) statement parameter:(id)parameter;

/**
 * Execute an update statement. The number of rows affected will be returned.
 * 更新记录
 * @param statement Unique identifier matching the statement to execute.
 * @return int The number of rows affected by the update.
 */
-(BOOL) update:(NSString *) statement;

/**
 * Execute an update statement. The number of rows affected will be returned.
 * 更新记录
 * @param statement Unique identifier matching the statement to execute.
 * @param parameter A parameter id to pass to the statement.
 * @return int The number of rows affected by the update.
 */
-(BOOL) update:(NSString *) statement parameter:(id) parameter;

/**
 * Execute a delete statement. The number of rows affected will be returned.
 * 删除记录
 * @param statement Unique identifier matching the statement to execute.
 * @return int The number of rows affected by the delete.
 */
-(BOOL) delete:(NSString *) statement;

/**
 * Execute a delete statement. The number of rows affected will be returned.
 * 删除记录
 * @param statement Unique identifier matching the statement to execute.
 * @param parameter A parameter id to pass to the statement.
 * @return int The number of rows affected by the delete.
 */
-(BOOL) delete:(NSString *) statement  parameter:(id) parameter;

//以下是事务控制方法,commit,rollback
/**
 * Flushes batch statements and commits database connection.
 * Note that database connection will not be committed if no updates/deletes/inserts were called.
 * To force the commit call {@link SqlSession#commit(boolean)}
 */
-(void) commit;

/**
 * Flushes batch statements and commits database connection.
 * @param force forces connection commit
 */
-(void) commit:(BOOL) force;

/**
 * Discards pending batch statements and rolls database connection back.
 * Note that database connection will not be rolled back if no updates/deletes/inserts were called.
 * To force the rollback call {@link SqlSession#rollback(boolean)}
 */
-(void) rollback;

/**
 * Discards pending batch statements and rolls database connection back.
 * Note that database connection will not be rolled back if no updates/deletes/inserts were called.
 * @param force forces connection rollback
 */
-(void) rollback:(BOOL) force;

/**
 * Closes the session
 * 关闭Session
 */
-(void) close;

/**
 * Clears local session cache
 * 清理Session缓存
 */
-(void) clearCache;

/**
 * Retrieves current configuration
 * 得到配置
 * @return Configuration
 */
//Configuration getConfiguration();


/**
 * Retrieves inner database connection
 * 得到数据库连接
 * @return Connection
 */
//Connection getConnection();
@end
