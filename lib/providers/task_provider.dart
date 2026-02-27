import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/supabase_service.dart';
import '../services/user_service.dart';

enum TaskFilter { all, pending, completed, priority, category }

class TaskProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final UserService _userService = UserService();

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  bool _isLoading = false;
  String _errorMessage = '';
  StreamSubscription? _tasksSubscription;

  // 搜索状态
  String _searchQuery = '';
  bool get isSearching => _searchQuery.isNotEmpty;

  // Getters
  List<Task> get tasks => _filteredTasks;
  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  TaskFilter get currentFilter => _currentFilter;

  // Statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;
  double get completionRate =>
      totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

  /// 初始化并开始监听任务变化
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      print('TaskProvider: Starting initialization...');

      // 首先加载一次初始数据
      print('TaskProvider: Loading initial tasks from Supabase...');
      _tasks = await _supabaseService.getAllTasks();
      print('TaskProvider: Loaded ${_tasks.length} tasks from Supabase');
      _applyFilter();
      _setLoading(false);

      // 然后开始监听任务变化
      print('TaskProvider: Starting stream listener...');
      _tasksSubscription = _supabaseService.watchTasks().listen(
        (tasks) {
          print('TaskProvider: Stream UPDATE received - ${tasks.length} tasks total');
          _tasks = tasks;
          _applyFilter();
          notifyListeners(); // 确保UI更新
          _setLoading(false);
        },
        onError: (error) {
          print('TaskProvider: Stream error - $error');
          _setError('监听任务失败: $error');
          _setLoading(false);
        },
        onDone: () {
          print('TaskProvider: Stream completed (this shouldn\'t happen)');
        },
      );
      print('TaskProvider: Stream listener started successfully');
    } catch (e) {
      print('TaskProvider: Initialize error - ${e.toString()}');
      _setError('初始化失败: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// 获取当前用户名
  Future<String?> getCurrentUsername() async {
    return await _userService.getUsername();
  }

  // Load tasks from Supabase (一次性加载)
  Future<void> loadTasks() async {
    _setLoading(true);
    _clearError();

    try {
      _tasks = await _supabaseService.getAllTasks();
      _currentFilter = TaskFilter.all;
      _filteredTasks = List.from(_tasks);
      notifyListeners();
    } catch (e) {
      _setError('加载任务失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 直接加载所有任务（不设置 loading 状态）
  Future<List<Task>> loadTasksDirectly() async {
    try {
      return await _supabaseService.getAllTasks();
    } catch (e) {
      _setError('加载任务失败: ${e.toString()}');
      return [];
    }
  }

  // 直接加载待办任务
  Future<List<Task>> loadPendingTasksDirectly() async {
    try {
      return await _supabaseService.getTasksByStatus(false);
    } catch (e) {
      _setError('加载待办任务失败: ${e.toString()}');
      return [];
    }
  }

  // 直接加载已完成任务
  Future<List<Task>> loadCompletedTasksDirectly() async {
    try {
      return await _supabaseService.getTasksByStatus(true);
    } catch (e) {
      _setError('加载已完成任务失败: ${e.toString()}');
      return [];
    }
  }

  // Add new task
  Future<void> addTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      // 获取当前用户名并添加到任务中
      final username = await _userService.getUsername();
      final taskWithCreator = task.copyWith(creatorName: username);

      await _supabaseService.createTask(taskWithCreator);
      // 由于使用实时监听，不需要手动重新加载
    } catch (e) {
      _setError('添加任务失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update existing task
  Future<void> updateTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.updateTask(task);
      // 由于使用实时监听，不需要手动重新加载
    } catch (e) {
      _setError('更新任务失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.deleteTask(taskId);
      // 由于使用实时监听，不需要手动重新加载
    } catch (e) {
      _setError('删除任务失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.userId == taskId);
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    } catch (e) {
      _setError('切换任务状态失败: ${e.toString()}');
    }
  }

  // Filter tasks
  Future<void> setFilter(TaskFilter filter) async {
    _currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  // Search tasks
  Future<void> searchTasks(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      // 清除搜索，恢复当前筛选
      _applyFilter();
    } else {
      try {
        // 执行搜索
        final lowerQuery = query.toLowerCase();
        _filteredTasks = _tasks.where((task) =>
            task.title.toLowerCase().contains(lowerQuery) ||
            (task.description?.toLowerCase().contains(lowerQuery) ?? false)
        ).toList();
      } catch (e) {
        _setError('搜索失败: ${e.toString()}');
        _applyFilter();
      }
    }
    notifyListeners();
  }

  // Get tasks by status
  Future<void> filterByStatus(bool isCompleted) async {
    _setLoading(true);
    _clearError();

    try {
      _tasks = await _supabaseService.getTasksByStatus(isCompleted);
      _filteredTasks = List.from(_tasks);
      notifyListeners();
    } catch (e) {
      _setError('筛选失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get tasks by priority
  Future<void> filterByPriority(TaskPriority priority) async {
    _setLoading(true);
    _clearError();

    try {
      _tasks = await _supabaseService.getTasksByPriority(priority);
      _filteredTasks = List.from(_tasks);
      notifyListeners();
    } catch (e) {
      _setError('筛选失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete all completed tasks
  Future<void> deleteCompletedTasks() async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.deleteCompletedTasks();
      // 由于使用实时监听，不需要手动重新加载
    } catch (e) {
      _setError('删除已完成任务失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Batch delete specified tasks
  Future<void> deleteSelectedTasks(List<String> taskIds) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.deleteSelectedTasks(taskIds);
      // 由于使用实时监听，不需要手动重新加载
    } catch (e) {
      _setError('批量删除失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Batch set completion status
  Future<void> setCompletionStatus(List<String> taskIds, bool isCompleted) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.setCompletionStatus(taskIds, isCompleted);
      // 由于使用实时监听，不需要手动重新加载
    } catch (e) {
      _setError('批量更新失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Export data
  Future<String?> exportData() async {
    try {
      return await _supabaseService.exportData();
    } catch (e) {
      _setError('导出失败: ${e.toString()}');
      return null;
    }
  }

  // Import data
  Future<bool> importData(List<Task> tasks) async {
    _setLoading(true);
    _clearError();

    try {
      final imported = await _supabaseService.importData(tasks);
      if (imported) {
        return true;
      }
      return false;
    } catch (e) {
      _setError('导入失败: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void _applyFilter() {
    // 如果正在搜索，不应用筛选（保持搜索结果）
    if (isSearching) {
      // 重新应用搜索到新的 _tasks 数据
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredTasks = _tasks.where((task) =>
          task.title.toLowerCase().contains(lowerQuery) ||
          (task.description?.toLowerCase().contains(lowerQuery) ?? false)
      ).toList();
      notifyListeners();
      return;
    }

    switch (_currentFilter) {
      case TaskFilter.all:
        _filteredTasks = List.from(_tasks);
        break;
      case TaskFilter.pending:
        _filteredTasks = _tasks.where((task) => !task.isCompleted).toList();
        break;
      case TaskFilter.completed:
        _filteredTasks = _tasks.where((task) => task.isCompleted).toList();
        break;
      case TaskFilter.priority:
        _filteredTasks = List.from(_tasks)
          ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TaskFilter.category:
        _filteredTasks = List.from(_tasks)
          ..sort((a, b) => a.category.index.compareTo(b.category.index));
        break;
    }
    notifyListeners();
  }
}
