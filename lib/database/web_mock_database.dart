import 'dart:async';
import 'dart:typed_data';
import 'package:sqflite_common/sqlite_api.dart';

class WebMockDatabaseFactory implements DatabaseFactory {
  final Map<String, WebMockDatabase> _databases = {};

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options}) async {
    if (!_databases.containsKey(path)) {
      final db = WebMockDatabase(this, path, options);
      _databases[path] = db;
      if (options?.onCreate != null) {
        await options!.onCreate!(db, options.version ?? 1);
      }
    }
    return _databases[path]!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class WebMockDatabase implements Database {
  final WebMockDatabaseFactory factory;
  @override
  final String path;
  final OpenDatabaseOptions? options;
  final Map<String, List<Map<String, Object?>>> _tables = {};

  WebMockDatabase(this.factory, this.path, this.options);

  @override
  Database get database => this;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final upperSql = sql.toUpperCase();
    if (upperSql.contains('CREATE TABLE')) {
      final tableName = _extractTableName(sql);
      if (tableName != null) {
        _tables[tableName] = [];
      }
    }
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    _tables[table] ??= [];
    final id = _tables[table]!.length + 1;
    final row = Map<String, Object?>.from(values);
    row['id'] = id;
    _tables[table]!.add(row);
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) async {
    var results = _tables[table] ?? [];
    if (where != null) {
      if (where.contains('id = ?')) {
        final id = whereArgs![0];
        results = results.where((r) => r['id'] == id).toList();
      }
    }
    if (limit != null) {
      results = results.take(limit).toList();
    }
    return results;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('COUNT(*)')) return [{'cnt': 0, 'total': 0, 'count': 0}];
    if (sql.contains('COALESCE(SUM(glasses)')) return [{'total': 0}];
    if (sql.contains('AVG(mood_score)')) return [{'avg_mood': 0}];
    return [];
  }

  @override
  Batch batch() => WebMockBatch(this);

  String? _extractTableName(String sql) {
    final match = RegExp(r'CREATE TABLE IF NOT EXISTS (\w+)').firstMatch(sql);
    return match?.group(1) ?? RegExp(r'CREATE TABLE (\w+)').firstMatch(sql)?.group(1);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    return await action(WebMockTransaction(this));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #isOpen) return true;
    if (invocation.memberName == #getVersion) return Future.value(options?.version ?? 1);
    return super.noSuchMethod(invocation);
  }
}

class WebMockTransaction implements Transaction {
  final WebMockDatabase db;
  WebMockTransaction(this.db);
  @override
  Database get database => db;
  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) => db.execute(sql, arguments);
  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) => db.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
  @override
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) => db.query(table, distinct: distinct, columns: columns, where: where, whereArgs: whereArgs, groupBy: groupBy, having: having, orderBy: orderBy, limit: limit, offset: offset);
  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) => db.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) => db.delete(table, where: where, whereArgs: whereArgs);
  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) => db.rawQuery(sql, arguments);
  @override
  Batch batch() => db.batch();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class WebMockBatch implements Batch {
  final WebMockDatabase db;
  final List<Future Function()> _ops = [];

  WebMockBatch(this.db);

  @override
  void insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    _ops.add(() => db.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm));
  }

  @override
  Future<List<Object?>> commit({bool? exclusive, bool? noResult, bool? continueOnError}) async {
    final results = <Object?>[];
    for (final op in _ops) {
      results.add(await op());
    }
    return results;
  }

  @override
  int get length => _ops.length;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
