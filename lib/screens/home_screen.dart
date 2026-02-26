import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import 'add_edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final Set<int> _selectedTaskIds = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    // Load tasks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (taskProvider.errorMessage.isNotEmpty) {
              return Center(
                child: Text(
                  taskProvider.errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (taskProvider.tasks.isEmpty) {
              return _buildEmptyState();
            }

            return TabBarView(
              children: [
                _buildTabContent(TaskFilter.all),
                _buildTabContent(TaskFilter.pending),
                _buildTabContent(TaskFilter.completed),
              ],
            );
          },
        ),
        floatingActionButton: _isMultiSelectMode
            ? null
            : FloatingActionButton(
                onPressed: () => _navigateToAddTask(context),
                tooltip: '添加任务',
                child: const Icon(Icons.add),
              ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isMultiSelectMode
          ? Text('${_selectedTaskIds.length} 个已选')
          : _isSearching
              ? _buildSearchField()
              : const Text('待办事项'),
      bottom: const TabBar(
        tabs: [
          Tab(text: '全部'),
          Tab(text: '待办'),
          Tab(text: '已完成'),
        ],
      ),
      actions: [
        if (_isMultiSelectMode)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _toggleMultiSelectMode(false),
            tooltip: '取消选择',
          )
        else ...[
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
              tooltip: '清除',
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
              tooltip: '搜索',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '筛选',
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角的 + 按钮添加新任务',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(TaskFilter filter) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Apply the filter to show relevant tasks
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (taskProvider.currentFilter != filter && !_isSearching) {
            taskProvider.setFilter(filter);
          }
        });

        // Show search results if searching
        final tasks = _isSearching
            ? taskProvider.tasks
            : filter == TaskFilter.all
                ? taskProvider.allTasks
                : filter == TaskFilter.completed
                    ? taskProvider.allTasks.where((t) => t.isCompleted).toList()
                    : taskProvider.allTasks.where((t) => !t.isCompleted).toList();

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return Stack(
          children: [
            ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskItem(task);
              },
            ),
            if (_isMultiSelectMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBatchActionBar(tasks),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTaskItem(Task task) {
    final isSelected = _selectedTaskIds.contains(task.id!);

    if (_isMultiSelectMode) {
      return ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (bool? value) {
            _toggleTaskSelection(task.id!);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                _buildPriorityChip(task.priority),
                const SizedBox(width: 8),
                _buildCategoryChip(task.category),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  Text(
                    ' ${task.dueDate!.month}/${task.dueDate!.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        tileColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
        onTap: () => _toggleTaskSelection(task.id!),
      );
    }

    return Dismissible(
      key: Key(task.id.toString()),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as completed
          await context.read<TaskProvider>().toggleTaskCompletion(task.id!);
          return false; // Don't dismiss the item
        } else {
          // Delete task
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<TaskProvider>().deleteTask(task.id!);
        }
      },
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (bool? value) {
            if (value != null) {
              context.read<TaskProvider>().toggleTaskCompletion(task.id!);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                _buildPriorityChip(task.priority),
                const SizedBox(width: 8),
                _buildCategoryChip(task.category),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  Text(
                    ' ${task.dueDate!.month}/${task.dueDate!.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _navigateToEditTask(context, task),
        ),
        onTap: () {},
        onLongPress: () {
          _toggleMultiSelectMode(true);
          _toggleTaskSelection(task.id!);
        },
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority) {
    Color color;
    switch (priority) {
      case TaskPriority.high:
        color = Colors.red;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        break;
      case TaskPriority.low:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        Task.getPriorityText(priority),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(TaskCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        Task.getCategoryText(category),
        style: const TextStyle(
          fontSize: 11,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总任务', taskProvider.totalTasks),
              _buildStatItem('已完成', taskProvider.completedTasks, Colors.green),
              _buildStatItem('待办', taskProvider.pendingTasks, Colors.orange),
              _buildProgressBar(taskProvider.completionRate),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, [Color? color]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double completionRate) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${completionRate.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: completionRate / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              completionRate == 100 ? Colors.green : Colors.blue,
            ),
          ),
          Text(
            '完成率',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditTaskScreen(),
      ),
    );
  }

  void _navigateToEditTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(task: task),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('筛选任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('按优先级'),
                onTap: () {
                  Navigator.pop(context);
                  _showPriorityFilterDialog();
                },
              ),
              ListTile(
                title: const Text('按分类'),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryFilterDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  void _showPriorityFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择优先级'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TaskPriority.values.map((priority) {
              return ListTile(
                title: Text(Task.getPriorityText(priority)),
                onTap: () {
                  context.read<TaskProvider>().filterByPriority(priority);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TaskCategory.values.map((category) {
              return ListTile(
                title: Text(Task.getCategoryText(category)),
                onTap: () {
                  // Implement category filter
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除这个任务吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Search methods
  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    context.read<TaskProvider>().loadTasks();
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: '搜索任务...',
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 18),
      onChanged: (query) {
        context.read<TaskProvider>().searchTasks(query);
      },
    );
  }

  // Selection mode methods
  void _toggleMultiSelectMode(bool enabled) {
    setState(() {
      _isMultiSelectMode = enabled;
      if (!enabled) {
        _selectedTaskIds.clear();
      }
    });
  }

  void _toggleTaskSelection(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _selectAllTasks(List<Task> tasks) {
    setState(() {
      _selectedTaskIds.clear();
      for (final task in tasks) {
        _selectedTaskIds.add(task.id!);
      }
    });
  }

  void _deselectAllTasks() {
    setState(() {
      _selectedTaskIds.clear();
      _isMultiSelectMode = false;
    });
  }

  Widget _buildBatchActionBar(List<Task> tasks) {
    final allSelected = _selectedTaskIds.length == tasks.length;
    final hasSelection = _selectedTaskIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Select all checkbox
            InkWell(
              onTap: () {
                if (allSelected) {
                  _deselectAllTasks();
                } else {
                  _selectAllTasks(tasks);
                }
              },
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected && tasks.isNotEmpty,
                    onChanged: (bool? value) {
                      if (allSelected) {
                        _deselectAllTasks();
                      } else {
                        _selectAllTasks(tasks);
                      }
                    },
                  ),
                  const Text('全选'),
                ],
              ),
            ),
            const Spacer(),
            // Batch delete button
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: hasSelection ? () => _performBatchDelete(context) : null,
              tooltip: '删除',
              color: Colors.red,
            ),
            // Batch complete button
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: hasSelection ? () => _performBatchComplete(context) : null,
              tooltip: '标记完成',
              color: Colors.green,
            ),
            // Batch incomplete button
            IconButton(
              icon: const Icon(Icons.radio_button_unchecked),
              onPressed: hasSelection ? () => _performBatchIncomplete(context) : null,
              tooltip: '标记未完成',
              color: Colors.orange,
            ),
            // Close button
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _toggleMultiSelectMode(false),
              tooltip: '取消',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performBatchDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除选中的 ${_selectedTaskIds.length} 个任务吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<TaskProvider>().deleteSelectedTasks(_selectedTaskIds.toList());
      _toggleMultiSelectMode(false);
    }
  }

  Future<void> _performBatchComplete(BuildContext context) async {
    await context.read<TaskProvider>().setCompletionStatus(_selectedTaskIds.toList(), true);
    _toggleMultiSelectMode(false);
  }

  Future<void> _performBatchIncomplete(BuildContext context) async {
    await context.read<TaskProvider>().setCompletionStatus(_selectedTaskIds.toList(), false);
    _toggleMultiSelectMode(false);
  }
}