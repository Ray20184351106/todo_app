import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/task.dart';

/// Firebase 服务类 - 使用 Cloud Firestore 存储数据
class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  factory FirebaseService() => instance;

  FirebaseService._init();

  final CollectionReference _tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  /// 初始化 Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  }

  /// 获取所有任务（一次性）
  Future<List<Task>> getAllTasks() async {
    try {
      final snapshot = await _tasksCollection.get();
      return snapshot.docs.map((doc) => _docToTask(doc)).toList();
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 根据状态获取任务
  Future<List<Task>> getTasksByStatus(bool isCompleted) async {
    try {
      final snapshot = await _tasksCollection
          .where('is_completed', isEqualTo: isCompleted)
          .get();
      return snapshot.docs.map((doc) => _docToTask(doc)).toList();
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 根据优先级获取任务
  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    try {
      final snapshot = await _tasksCollection
          .where('priority', isEqualTo: priority.index)
          .get();
      return snapshot.docs.map((doc) => _docToTask(doc)).toList();
    } catch (e) {
      throw Exception('获取任务失败: $e');
    }
  }

  /// 搜索任务
  Future<List<Task>> searchTasks(String query) async {
    try {
      final snapshot = await _tasksCollection.get();
      final tasks = snapshot.docs.map((doc) => _docToTask(doc)).toList();

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
      final docRef = await _tasksCollection.add(_taskToMap(task));
      return docRef.id;
    } catch (e) {
      throw Exception('创建任务失败: $e');
    }
  }

  /// 更新任务
  Future<void> updateTask(Task task) async {
    try {
      if (task.userId == null) {
        throw Exception('任务 ID 不能为空');
      }
      await _tasksCollection.doc(task.userId).update(_taskToMap(task));
    } catch (e) {
      throw Exception('更新任务失败: $e');
    }
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw Exception('删除任务失败: $e');
    }
  }

  /// 删除已完成的任务
  Future<int> deleteCompletedTasks() async {
    try {
      final snapshot = await _tasksCollection
          .where('is_completed', isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('删除已完成任务失败: $e');
    }
  }

  /// 批量删除任务
  Future<void> deleteSelectedTasks(List<String> taskIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final taskId in taskIds) {
        final docRef = _tasksCollection.doc(taskId);
        batch.delete(docRef);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('批量删除失败: $e');
    }
  }

  /// 批量设置完成状态
  Future<void> setCompletionStatus(List<String> taskIds, bool isCompleted) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final taskId in taskIds) {
        final docRef = _tasksCollection.doc(taskId);
        batch.update(docRef, {
          'is_completed': isCompleted,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('批量更新失败: $e');
    }
  }

  /// 导出数据
  Future<String?> exportData() async {
    try {
      final snapshot = await _tasksCollection.get();
      final tasks = snapshot.docs.map((doc) => _docToTask(doc)).toList();

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
      final batch = FirebaseFirestore.instance.batch();
      for (final task in tasks) {
        final docRef = _tasksCollection.doc();
        batch.set(docRef, _taskToMap(task));
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 监听任务变化（实时同步）
  Stream<List<Task>> watchTasks() {
    return _tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _docToTask(doc)).toList();
    });
  }

  /// 将 Firestore 文档转换为 Task 对象
  Task _docToTask(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 处理 is_completed
    final isCompletedValue = data['is_completed'];
    final bool isCompleted = isCompletedValue is bool
        ? isCompletedValue
        : (isCompletedValue == 1);

    // 处理 due_date - 可能是 Timestamp、ISO 字符串或时间戳
    DateTime? dueDate;
    final dynamic dueDateValue = data['due_date'];
    if (dueDateValue != null) {
      if (dueDateValue is Timestamp) {
        dueDate = dueDateValue.toDate();
      } else if (dueDateValue is String) {
        dueDate = DateTime.parse(dueDateValue);
      } else if (dueDateValue is int) {
        dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateValue);
      }
    }

    // 处理 created_at 和 updated_at
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return Task(
      id: int.tryParse(doc.id), // 尝试解析为整数，失败则为 null
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      isCompleted: isCompleted,
      priority: TaskPriority.values[data['priority'] ?? 1],
      category: TaskCategory.values[data['category'] ?? 4],
      dueDate: dueDate,
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
      userId: doc.id, // 使用 Firestore 文档 ID 作为 userId
      creatorName: data['creator_name'] as String?,
    );
  }

  /// 将 Task 对象转换为 Firestore Map
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'is_completed': task.isCompleted,
      'priority': task.priority.index,
      'category': task.category.index,
      'due_date': task.dueDate?.toIso8601String(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'user_id': task.userId,
      'creator_name': task.creatorName,
    };
  }
}
