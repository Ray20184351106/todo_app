import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory { work, personal, shopping, health, other }

class Task extends Equatable {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final String? creatorName;

  const Task({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.other,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.creatorName,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? creatorName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      creatorName: creatorName ?? this.creatorName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority.index,
      'category': category.index,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'user_id': userId,
      'creator_name': creatorName,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // 处理 is_completed - 可能是 bool 或 int
    final isCompletedValue = map['is_completed'];
    final bool isCompleted = isCompletedValue is bool
        ? isCompletedValue
        : (isCompletedValue == 1);

    // 处理 due_date - 可能是 ISO 字符串或时间戳
    final dynamic dueDateValue = map['due_date'];
    DateTime? dueDate;
    if (dueDateValue != null) {
      if (dueDateValue is String) {
        dueDate = DateTime.parse(dueDateValue);
      } else if (dueDateValue is int) {
        dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateValue);
      }
    }

    // 处理 created_at 和 updated_at - 可能是 ISO 字符串或时间戳
    DateTime parseDateTime(dynamic value) {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: isCompleted,
      priority: TaskPriority.values[map['priority'] ?? 1],
      category: TaskCategory.values[map['category'] ?? 4],
      dueDate: dueDate,
      createdAt: parseDateTime(map['created_at']),
      updatedAt: parseDateTime(map['updated_at']),
      userId: map['user_id'] as String?,
      creatorName: map['creator_name'] as String?,
    );
  }

  factory Task.create({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.other,
    DateTime? dueDate,
    String? userId,
  }) {
    final now = DateTime.now();
    return Task(
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        isCompleted,
        priority,
        category,
        dueDate,
        createdAt,
        updatedAt,
        userId,
        creatorName,
      ];

  static String getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
    }
  }

  static String getCategoryText(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return '工作';
      case TaskCategory.personal:
        return '个人';
      case TaskCategory.shopping:
        return '购物';
      case TaskCategory.health:
        return '健康';
      case TaskCategory.other:
        return '其他';
    }
  }
}
