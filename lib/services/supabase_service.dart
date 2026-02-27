import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

/// Supabase 服务类 - 使用 Supabase 存储数据
class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  factory SupabaseService() => instance;

  SupabaseService._init();

  late final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _tasksSubscription;

  /// 获取 Supabase 客户端
  SupabaseClient get client => _client;

  /// 初始化 Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://zyalukxbwvccahtjkumk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5YWx1a3hid3ZjY2FodGprdW1rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNDQwNTUsImV4cCI6MjA4NzcyMDA1NX0.AEqNB3S-ooCbhtGA-dxsy0UEAE6xpLNmTpMnYT1EBKM',
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 40,
      ),
    );
    instance._client = Supabase.instance.client;
    print('SupabaseService: Initialized with realtime support');
  }

  /// 获取所有任务（一次性）
  Future<List<Task>> getAllTasks() async {
    try {
      print('SupabaseService: Fetching all tasks...');
      final response = await _client
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      print('SupabaseService: Got response: ${response.length} items');
      final tasks = (response as List).map((data) => _mapToTask(data as Map<String, dynamic>)).toList();
      print('SupabaseService: Mapped to ${tasks.length} Task objects');
      return tasks;
    } catch (e) {
      print('SupabaseService: Error - $e');
      throw Exception('获取任务失败: $e');
    }
  }

  /// 根据状态获取任务
  Future<List<Task>> getTasksByStatus(bool isCompleted) async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('is_completed', isCompleted)
          .order('created_at', ascending: false);
      return (response as List).map((data) => _mapToTask(data as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 根据优先级获取任务
  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('priority', priority.index)
          .order('created_at', ascending: false);
      return (response as List).map((data) => _mapToTask(data as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 搜索任务
  Future<List<Task>> searchTasks(String query) async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      final tasks = (response as List).map((data) => _mapToTask(data as Map<String, dynamic>)).toList();

      // 客户端过滤
      final lowerQuery = query.toLowerCase();
      return tasks
          .where((task) =>
              task.title.toLowerCase().contains(lowerQuery) ||
              (task.description?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    } catch (e) {
      throw Exception('搜索任务失败: $e');
    }
  }

  /// 创建任务
  Future<String> createTask(Task task) async {
    try {
      final data = _taskToMap(task);
      final response = await _client.from('tasks').insert(data).select();
      return (response as List).first['id'] as String;
    } catch (e) {
      throw Exception('创建任务失败: $e');
    }
  }

  /// 更新任务
  Future<void> updateTask(Task task) async {
    try {
      final taskId = task.userId;
      if (taskId == null) {
        throw Exception('任务 ID 不能为空');
      }
      final data = _taskToMap(task);
      data['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('tasks').update(data).eq('id', taskId);
    } catch (e) {
      throw Exception('更新任务失败: $e');
    }
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      throw Exception('删除任务失败: $e');
    }
  }

  /// 删除已完成的任务
  Future<int> deleteCompletedTasks() async {
    try {
      final response = await _client.from('tasks').delete().eq('is_completed', true).select();
      return (response as List).length;
    } catch (e) {
      throw Exception('删除已完成任务失败: $e');
    }
  }

  /// 批量删除任务
  Future<void> deleteSelectedTasks(List<String> taskIds) async {
    try {
      await _client.from('tasks').delete().inFilter('id', taskIds);
    } catch (e) {
      throw Exception('批量删除失败: $e');
    }
  }

  /// 批量设置完成状态
  Future<void> setCompletionStatus(List<String> taskIds, bool isCompleted) async {
    try {
      await _client
          .from('tasks')
          .update({
        'is_completed': isCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .inFilter('id', taskIds);
    } catch (e) {
      throw Exception('批量更新失败: $e');
    }
  }

  /// 导出数据
  Future<String?> exportData() async {
    try {
      final response = await _client.from('tasks').select();
      final tasks = (response as List).map((data) => _mapToTask(data as Map<String, dynamic>)).toList();

      if (tasks.isEmpty) return null;

      final buffer = StringBuffer();
      buffer.writeln('title,description,is_completed,priority,category,due_date,created_at,creator_name');

      for (final task in tasks) {
        buffer.writeln(
          '${task.title},'
          '${task.description ?? ''},'
          '${task.isCompleted},'
          '${task.priority.index},'
          '${task.category.index},'
          '${task.dueDate?.toIso8601String() ?? ''},'
          '${task.createdAt.toIso8601String()},'
          '${task.creatorName ?? ''}',
        );
      }

      return buffer.toString();
    } catch (e) {
      return null;
    }
  }

  /// 导入数据
  Future<bool> importData(List<Task> tasks) async {
    try {
      final dataList = tasks.map((task) => _taskToMap(task)).toList();
      await _client.from('tasks').insert(dataList);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 监听任务变化（实时同步）
  Stream<List<Task>> watchTasks() {
    print('SupabaseService: Setting up realtime stream for tasks table...');
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((event) {
      print('SupabaseService: Stream event received with ${event.length} items');
      return event.map((data) => _mapToTask(data)).toList();
    });
  }

  /// 将数据库 Map 转换为 Task 对象
  Task _mapToTask(Map<String, dynamic> data) {
    // 处理 is_completed
    final isCompleted = data['is_completed'] is bool
        ? data['is_completed'] as bool
        : (data['is_completed'] == 1 || data['is_completed'] == 'true');

    // 处理 due_date
    DateTime? dueDate;
    final dynamic dueDateValue = data['due_date'];
    if (dueDateValue != null) {
      if (dueDateValue is String) {
        dueDate = DateTime.parse(dueDateValue);
      } else if (dueDateValue is DateTime) {
        dueDate = dueDateValue as DateTime;
      }
    }

    // 处理 created_at 和 updated_at
    DateTime parseDateTime(dynamic value) {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value as DateTime;
      }
      return DateTime.now();
    }

    // 安全获取字符串值
    String? getString(String key) {
      final value = data[key];
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    // 安全获取整数值
    int getInt(String key, int defaultValue) {
      final value = data[key];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Task(
      id: null, // Supabase 使用字符串 ID
      title: getString('title') ?? '',
      description: getString('description'),
      isCompleted: isCompleted,
      priority: TaskPriority.values[getInt('priority', 1)],
      category: TaskCategory.values[getInt('category', 4)],
      dueDate: dueDate,
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
      userId: getString('id'), // 使用 Supabase 的 id 字段
      creatorName: getString('creator_name'),
    );
  }

  /// 将 Task 对象转换为数据库 Map
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'is_completed': task.isCompleted,
      'priority': task.priority.index,
      'category': task.category.index,
      'due_date': task.dueDate?.toIso8601String(),
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
      'creator_name': task.creatorName,
    };
  }
}
