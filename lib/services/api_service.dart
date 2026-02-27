import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/task.dart';

/// API 服务类 - 连接到 MySQL 后端
class ApiService {
  static final ApiService instance = ApiService._init();
  factory ApiService() => instance;

  // API 基础 URL
  static String _baseUrl = 'http://localhost:5000/api';

  ApiService._init();

  /// 设置 API 基础 URL
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// 获取基础 URL
  String get baseUrl => _baseUrl;

  /// 获取所有任务
  Future<List<Task>> getAllTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((task) => Task.fromMap(task)).toList();
      }
      throw Exception('获取任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 根据状态获取任务
  Future<List<Task>> getTasksByStatus(bool isCompleted) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks?is_completed=$isCompleted'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((task) => Task.fromMap(task)).toList();
      }
      throw Exception('获取任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 根据优先级获取任务
  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks?priority=${priority.index}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((task) => Task.fromMap(task)).toList();
      }
      throw Exception('获取任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 搜索任务
  Future<List<Task>> searchTasks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks?search=$query'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((task) => Task.fromMap(task)).toList();
      }
      throw Exception('搜索任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('搜索任务失败: $e');
    }
  }

  /// 创建任务
  Future<int> createTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toMap()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json['id'] as int;
      }
      throw Exception('创建任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('创建任务失败: $e');
    }
  }

  /// 更新任务
  Future<int> updateTask(Task task) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toMap()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return 1;
      }
      throw Exception('更新任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('更新任务失败: $e');
    }
  }

  /// 删除任务
  Future<int> deleteTask(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return 1;
      }
      throw Exception('删除任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('删除任务失败: $e');
    }
  }

  /// 删除已完成的任务
  Future<int> deleteCompletedTasks() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/completed'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 从响应中获取删除的数量
        final Map<String, dynamic> json = jsonDecode(response.body);
        final message = json['message'] as String;
        // 解析 "已删除 X 个任务"
        final match = RegExp(r'\d+').firstMatch(message);
        return match != null ? int.parse(match.group(0)!) : 0;
      }
      throw Exception('删除已完成任务失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('删除已完成任务失败: $e');
    }
  }

  /// 批量删除任务
  Future<void> deleteSelectedTasks(List<int> taskIds) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ids': taskIds}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('批量删除失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('批量删除失败: $e');
    }
  }

  /// 批量设置完成状态
  Future<void> setCompletionStatus(List<int> taskIds, bool isCompleted) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/batch/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ids': taskIds,
          'is_completed': isCompleted,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('批量更新失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('批量更新失败: $e');
    }
  }

  /// 导出数据
  Future<String?> exportData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/export'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 导入数据
  Future<bool> importData(List<Task> tasks) async {
    try {
      // 逐个创建任务
      for (final task in tasks) {
        await createTask(task);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
