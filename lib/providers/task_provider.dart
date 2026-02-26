import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/database_service.dart';

enum TaskFilter { all, pending, completed, priority, category }

class TaskProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  TaskProvider({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  bool _isLoading = false;
  String _errorMessage = '';

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

  // Load tasks from database
  Future<void> loadTasks() async {
    _setLoading(true);
    _clearError();

    try {
      _tasks = await _databaseService.getAllTasks();
      _applyFilter();
    } catch (e) {
      _setError('Failed to load tasks: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add new task
  Future<void> addTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      final taskId = await _databaseService.createTask(task);

      // Reload tasks to reflect changes
      await loadTasks();
    } catch (e) {
      _setError('Failed to add task: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update existing task
  Future<void> updateTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRows = await _databaseService.updateTask(task);

      if (updatedRows > 0) {
        // Find and update task in the local list
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
          _applyFilter();
        }
      }
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete task
  Future<void> deleteTask(int taskId) async {
    _setLoading(true);
    _clearError();

    try {
      final deletedRows = await _databaseService.deleteTask(taskId);

      if (deletedRows > 0) {
        _tasks.removeWhere((task) => task.id == taskId);
        _applyFilter();
      }
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(int taskId) async {
    final task = _tasks.firstWhere((task) => task.id == taskId);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  // Filter tasks
  Future<void> setFilter(TaskFilter filter) async {
    _currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  // Search tasks
  Future<void> searchTasks(String query) async {
    if (query.isEmpty) {
      _filteredTasks = List.from(_tasks);
    } else {
      _filteredTasks = await _databaseService.searchTasks(query);
    }
    notifyListeners();
  }

  // Get tasks by status
  Future<void> filterByStatus(bool isCompleted) async {
    _tasks = await _databaseService.getTasksByStatus(isCompleted);
    _filteredTasks = List.from(_tasks);
    notifyListeners();
  }

  // Get tasks by priority
  Future<void> filterByPriority(TaskPriority priority) async {
    _tasks = await _databaseService.getTasksByPriority(priority);
    _filteredTasks = List.from(_tasks);
    notifyListeners();
  }

  // Delete all completed tasks
  Future<void> deleteCompletedTasks() async {
    _setLoading(true);
    _clearError();

    try {
      final deletedCount = await _databaseService.deleteCompletedTasks();
      if (deletedCount > 0) {
        _tasks.removeWhere((task) => task.isCompleted);
        _applyFilter();
      }
    } catch (e) {
      _setError('Failed to delete completed tasks: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Export data
  Future<String?> exportData() async {
    try {
      return await _databaseService.exportData();
    } catch (e) {
      _setError('Failed to export data: ${e.toString()}');
      return null;
    }
  }

  // Import data
  Future<bool> importData(List<Task> tasks) async {
    _setLoading(true);
    _clearError();

    try {
      final importedCount = await _databaseService.importData(tasks);
      if (importedCount > 0) {
        await loadTasks();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to import data: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
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
  }
}
