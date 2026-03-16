import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WebStorage {
  static const String _keyPrefix = 'growthmate_db_';

  static Future<void> save(String table, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrefix + table, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> load(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_keyPrefix + table);
    if (json == null) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<int> insert(String table, Map<String, dynamic> values) async {
    final data = await load(table);
    final int nextId = data.isEmpty ? 1 : (data.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final Map<String, dynamic> newRow = Map<String, dynamic>.from(values);
    newRow['id'] = nextId;
    data.add(newRow);
    await save(table, data);
    return nextId;
  }

  static Future<void> delete(String table, int id) async {
    final data = await load(table);
    data.removeWhere((e) => e['id'] == id);
    await save(table, data);
  }

  static Future<void> update(String table, int id, Map<String, dynamic> values) async {
    final data = await load(table);
    final index = data.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      data[index].addAll(values);
      await save(table, data);
    }
  }
}
