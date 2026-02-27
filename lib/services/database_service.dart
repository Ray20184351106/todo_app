import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/app_constants.dart';
import '../models/task.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init() {
    if (!kIsWeb) {
      // 仅在非 Web 平台初始化 FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else {
      // Web 平台使用默认的内存数据库
      // 注意：Web 平台数据不会持久化
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    if (kIsWeb) {
      // Web 平台使用内存数据库
      return await openDatabase(
        fileName,
        version: AppConstants.databaseVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }

    // 移动平台使用文件数据库
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 1,
        category INTEGER NOT NULL DEFAULT 4,
        due_date INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        user_id TEXT
      )
    ''');

    // Add index for better query performance
    await db.execute('''
      CREATE INDEX idx_tasks_completed ON tasks(is_completed)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_priority ON tasks(priority)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_updated_at ON tasks(updated_at)
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here in future versions
    if (oldVersion < 2) {
      // Add migration code for version 2
    }
  }

  // Task CRUD operations
  Future<int> createTask(Task task) async {
    final db = await instance.database;

    // Ensure no ID is set for new tasks
    final taskData = task.copyWith(id: null).toMap();

    return await db.insert(
      'tasks',
      taskData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Task?> getTask(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'tasks',
      columns: ['*'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;

    const orderBy = 'updated_at DESC';
    final result = await db.query('tasks', orderBy: orderBy);

    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getTasksByStatus(bool isCompleted) async {
    final db = await instance.database;

    const orderBy = 'updated_at DESC';
    final result = await db.query(
      'tasks',
      where: 'is_completed = ?',
      whereArgs: [isCompleted ? 1 : 0],
      orderBy: orderBy,
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    final db = await instance.database;

    const orderBy = 'updated_at DESC';
    final result = await db.query(
      'tasks',
      where: 'priority = ?',
      whereArgs: [priority.index],
      orderBy: orderBy,
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> searchTasks(String query) async {
    final db = await instance.database;

    const orderBy = 'updated_at DESC';
    final result = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: orderBy,
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;

    final updatedTask = task.copyWith(updatedAt: DateTime.now());

    return await db.update(
      'tasks',
      updatedTask.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;

    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCompletedTasks() async {
    final db = await instance.database;

    return await db.delete(
      'tasks',
      where: 'is_completed = ?',
      whereArgs: [1],
    );
  }

  Future<int> getTaskCount() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT COUNT(*) FROM tasks');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCompletedTaskCount() async {
    final db = await instance.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE is_completed = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Data export/import methods
  Future<String> exportData() async {
    final tasks = await getAllTasks();
    final taskMaps = tasks.map((task) => task.toMap()).toList();

    // Add metadata
    final exportData = {
      'version': AppConstants.databaseVersion.toString(),
      'export_date': DateTime.now().toIso8601String(),
      'tasks': taskMaps,
    };

    return exportData.toString();
  }

  Future<int> importData(List<Task> tasks) async {
    final db = await instance.database;

    // Use transaction for batch insert
    final batch = db.batch();

    for (final task in tasks) {
      batch.insert('tasks', task.toMap());
    }

    final results = await batch.commit(continueOnError: true);
    return results.length;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
