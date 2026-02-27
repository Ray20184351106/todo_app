import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/user_service.dart';
import 'add_edit_task_screen.dart';
import 'user_name_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final Set<String> _selectedTaskIds = {};
  bool _isMultiSelectMode = false;
  String _username = '';

  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // FAB 动画
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _fabAnimationController.forward();

    // 加载用户名
    _loadUsername();

    // 初始化时设置为"全部"过滤器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().setFilter(TaskFilter.all);
    });
  }

  Future<void> _loadUsername() async {
    final userService = UserService();
    final username = await userService.getUsername();
    if (mounted) {
      setState(() {
        _username = username ?? '用户';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // 处理标签页切换
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    final index = _tabController.index;
    final provider = context.read<TaskProvider>();

    switch (index) {
      case 0:
        provider.setFilter(TaskFilter.all);
        break;
      case 1:
        provider.setFilter(TaskFilter.pending);
        break;
      case 2:
        provider.setFilter(TaskFilter.completed);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 自定义头部（包含欢迎信息和用户名）
                  _buildHeader(taskProvider),
                  // TabBar
                  _buildAnimatedTabBar(taskProvider),
                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent(TaskFilter.all, taskProvider),
                        _buildTabContent(TaskFilter.pending, taskProvider),
                        _buildTabContent(TaskFilter.completed, taskProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : ScaleTransition(
              scale: _fabAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB7C5).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () => _navigateToAddTask(context),
                  tooltip: '添加任务',
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('添加任务', style: TextStyle(color: Colors.white)),
                  backgroundColor: const Color(0xFFFFB7C5),
                  elevation: 0,
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 构建头部（欢迎信息 + 搜索/操作栏）
  Widget _buildHeader(TaskProvider taskProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎信息行
          if (!_isSearching && !_isMultiSelectMode) ...[
            Row(
              children: [
                  // Hello Kitty 头像
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFB7C5).withOpacity(0.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/kitty_face.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '你好, $_username!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLoveGreeting(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 退出登录按钮
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFFFF8FAB)),
                    onPressed: _logout,
                    tooltip: '退出登录',
                  ),
                ],
            ),
            const SizedBox(height: 16),
          ],
          // 搜索栏或标题行
          _isMultiSelectMode
              ? _buildMultiSelectHeader()
              : _isSearching
                  ? _buildSearchBar()
                  : _buildActionBar(),
        ],
      ),
    );
  }

  // 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '早上好，今天有什么计划？';
    } else if (hour < 18) {
      return '下午好，继续加油！';
    } else {
      return '晚上好，今天辛苦了！';
    }
  }

  // 获取情侣问候语
  String _getLoveGreeting() {
    if (_username == '小雷') {
      return '今天也要爱小芬~';
    } else if (_username == '芬芬') {
      return '今天也要爱小雷~';
    }
    return '今天也要加油哦~';
  }

  // 多选模式头部
  Widget _buildMultiSelectHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '已选择 ${_selectedTaskIds.length} 个任务',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _toggleMultiSelectMode(false),
            tooltip: '取消选择',
          ),
        ],
      ),
    );
  }

  // 搜索栏
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '搜索任务...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (query) {
          context.read<TaskProvider>().searchTasks(query);
        },
      ),
    );
  }

  // 操作栏（搜索 + 筛选按钮）
  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _startSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[500]),
                  const SizedBox(width: 12),
                  Text(
                    '搜索任务...',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '筛选',
          ),
        ),
      ],
    );
  }

  // 动画标签栏
  Widget _buildAnimatedTabBar(TaskProvider taskProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        tabs: [
          Tab(text: '全部 (${taskProvider.allTasks.length})'),
          Tab(text: '待办 (${taskProvider.allTasks.where((t) => !t.isCompleted).length})'),
          Tab(text: '已完成 (${taskProvider.allTasks.where((t) => t.isCompleted).length})'),
        ],
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hello Kitty 拿相机图片
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Image.asset(
                  'assets/images/kitty_camera.png',
                  width: 120,
                  height: 120,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            '暂无任务~',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加新任务吧!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(TaskFilter filter, TaskProvider taskProvider) {
    final tasks = _getTasksForFilter(filter, taskProvider);

    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // 任务列表
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            key: ValueKey('${filter}_${tasks.length}'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return AnimatedTaskItem(
                key: ValueKey(task.userId),
                task: task,
                index: index,
                isSelected: _selectedTaskIds.contains(task.userId),
                isMultiSelectMode: _isMultiSelectMode,
                onSelect: () => _toggleTaskSelection(task.userId!),
                onToggleComplete: () => context.read<TaskProvider>().toggleTaskCompletion(task.userId!),
                onEdit: () => _navigateToEditTask(context, task),
                onDelete: () => _deleteTask(task),
                onDirectDelete: () => context.read<TaskProvider>().deleteTask(task.userId!),
                onLongPress: () => _enterMultiSelectMode(task.userId!),
              );
            },
          ),
        ),
        // 批量操作栏
        if (_isMultiSelectMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBatchActionBar(tasks),
          ),
      ],
    );
  }

  // 根据过滤器获取任务列表
  List<Task> _getTasksForFilter(TaskFilter filter, TaskProvider provider) {
    final baseTasks = provider.isSearching ? provider.tasks : provider.allTasks;

    switch (filter) {
      case TaskFilter.all:
        return baseTasks;
      case TaskFilter.pending:
        return baseTasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return baseTasks.where((t) => t.isCompleted).toList();
      case TaskFilter.priority:
      case TaskFilter.category:
        return baseTasks;
    }
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
                color: const Color(0xFFFFB7C5).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总任务', taskProvider.totalTasks, const Color(0xFFFF8FAB)),
              _buildStatItem('已完成', taskProvider.completedTasks, const Color(0xFF98D8AA)),
              _buildStatItem('待办', taskProvider.pendingTasks, const Color(0xFFFFB7C5)),
              _buildProgressBar(taskProvider.completionRate),
              // 右下角小 Kitty 装饰
              Image.asset(
                'assets/images/kitty_side.png',
                width: 28,
                height: 28,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, animatedValue, child) {
            return Text(
              animatedValue.toInt().toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: completionRate == 100 ? const Color(0xFF98D8AA) : const Color(0xFFFF8FAB),
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: completionRate / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: completionRate == 100
                          ? [const Color(0xFF98D8AA), const Color(0xFFB8E6C8)]
                          : [const Color(0xFFFFB7C5), const Color(0xFFFFD1DC)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
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

  // 退出登录
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('确认退出'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB7C5),
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final userService = UserService();
      await userService.clearUsername();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserNameScreen()),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('确认删除'),
          content: Text('确定要删除任务 "${task.title}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<TaskProvider>().deleteTask(task.userId!);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '筛选任务',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('按优先级'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showPriorityFilterDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.category, color: Colors.blue),
                title: const Text('按分类'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryFilterDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPriorityFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('选择优先级'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TaskPriority.values.map((priority) {
              Color priorityColor;
              switch (priority) {
                case TaskPriority.high:
                  priorityColor = const Color(0xFFFF6B8A);
                  break;
                case TaskPriority.medium:
                  priorityColor = const Color(0xFFFFB7C5);
                  break;
                case TaskPriority.low:
                  priorityColor = const Color(0xFF98D8AA);
                  break;
              }
              return ListTile(
                leading: Icon(
                  Icons.flag,
                  color: priorityColor,
                ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('选择分类'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TaskCategory.values.length,
              itemBuilder: (context, index) {
                final category = TaskCategory.values[index];
                return ListTile(
                  leading: Icon(
                    _getCategoryIcon(category),
                    color: const Color(0xFFFF8FAB),
                  ),
                  title: Text(Task.getCategoryText(category)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.personal:
        return Icons.person;
      case TaskCategory.shopping:
        return Icons.shopping_cart;
      case TaskCategory.health:
        return Icons.favorite;
      case TaskCategory.other:
        return Icons.more_horiz;
    }
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
    context.read<TaskProvider>().searchTasks('');
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

  void _enterMultiSelectMode(String taskId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedTaskIds.add(taskId);
    });
  }

  void _toggleTaskSelection(String taskId) {
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
        _selectedTaskIds.add(task.userId!);
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
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
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
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: hasSelection ? () => _performBatchDelete(context) : null,
              tooltip: '删除',
              color: Colors.red,
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: hasSelection ? () => _performBatchComplete(context) : null,
              tooltip: '标记完成',
              color: Colors.green,
            ),
            IconButton(
              icon: const Icon(Icons.radio_button_unchecked),
              onPressed: hasSelection ? () => _performBatchIncomplete(context) : null,
              tooltip: '标记未完成',
              color: Colors.orange,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('确认删除'),
          content: Text('确定要删除选中的 ${_selectedTaskIds.length} 个任务吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
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

// 动画任务项组件
class AnimatedTaskItem extends StatefulWidget {
  final Task task;
  final int index;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onSelect;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDirectDelete; // 直接删除，不需要再确认
  final VoidCallback onLongPress;

  const AnimatedTaskItem({
    super.key,
    required this.task,
    required this.index,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onSelect,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onDirectDelete,
    required this.onLongPress,
  });

  @override
  State<AnimatedTaskItem> createState() => _AnimatedTaskItemState();
}

class _AnimatedTaskItemState extends State<AnimatedTaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.isMultiSelectMode
            ? _buildTaskCard()
            : Dismissible(
                key: Key(widget.task.userId ?? widget.task.id.toString()),
                // 左滑标记完成
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                // 右滑删除
                secondaryBackground: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // 左滑 -> 标记完成/未完成
                    widget.onToggleComplete();
                    return false; // 不移除卡片
                  } else {
                    // 右滑 -> 删除
                    final confirmed = await _showDeleteConfirmation(context);
                    if (confirmed == true) {
                      // 用户确认后直接删除，返回 false 让 Dismissible 不处理移除
                      // 实时流会自动更新列表
                      widget.onDirectDelete();
                    }
                    return false; // 始终返回 false，让数据更新来移除卡片
                  }
                },
                child: _buildTaskCard(),
              ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('确认删除'),
          content: Text('确定要删除任务 "${widget.task.title}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 获取优先级颜色
  Color _getPriorityColor() {
    if (widget.task.isCompleted) {
      return Colors.grey;
    }
    switch (widget.task.priority) {
      case TaskPriority.high:
        return const Color(0xFFFF6B8A); // 玫瑰红
      case TaskPriority.medium:
        return const Color(0xFFFFB7C5); // 樱花粉
      case TaskPriority.low:
        return const Color(0xFF98D8AA); // 薄荷绿
    }
  }

  // 获取优先级背景色
  Color _getPriorityBackgroundColor() {
    if (widget.task.isCompleted) {
      return Colors.grey.withValues(alpha: 0.12); // 已完成用灰色背景
    }
    final priorityColor = _getPriorityColor();
    return priorityColor.withValues(alpha: 0.05);
  }

  Widget _buildTaskCard() {
    final isCompleted = widget.task.isCompleted;
    final priorityColor = _getPriorityColor();
    final backgroundColor = _getPriorityBackgroundColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.black.withValues(alpha: 0.02)
                : priorityColor.withValues(alpha: 0.15),
            blurRadius: isCompleted ? 5 : 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: widget.isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : isCompleted
                ? Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1.5)
                : Border.all(color: priorityColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Stack(
        children: [
          // 左侧优先级指示条
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey.withValues(alpha: 0.5) : priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          // 已完成任务的划掉效果
          if (isCompleted)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isCompleted ? 1.0 : 0.0,
                child: CustomPaint(
                  painter: StrikethroughPainter(
                    color: Colors.grey.withValues(alpha: 0.4),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          // 主要内容
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.isMultiSelectMode ? widget.onSelect : null,
              onLongPress: widget.isMultiSelectMode ? null : widget.onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(width: 8), // 为左侧指示条留出空间
                    // 复选框或选择指示器
                    GestureDetector(
                      onTap: widget.isMultiSelectMode ? widget.onSelect : widget.onToggleComplete,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.task.isCompleted
                              ? Colors.grey[500]
                              : widget.isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                          border: Border.all(
                            color: widget.task.isCompleted
                                ? Colors.grey[500]!
                                : widget.isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : priorityColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: widget.task.isCompleted
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: widget.task.isCompleted || widget.isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 任务内容
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题行（包含标题和已完成标签）
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: widget.task.isCompleted
                                        ? Colors.grey[500]
                                        : (widget.task.priority == TaskPriority.high && !widget.task.isCompleted
                                            ? Colors.red[700]
                                            : null),
                                  ),
                                  child: Text(
                                    widget.task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (widget.task.isCompleted) ...[
                                const SizedBox(width: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '已完成',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // 描述
                          if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.task.isCompleted ? Colors.grey[400] : Colors.grey[600],
                                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                              child: Text(
                                widget.task.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // 标签行
                          Row(
                            children: [
                              _buildPriorityChip(widget.task.priority),
                              const SizedBox(width: 8),
                              _buildCategoryChip(widget.task.category),
                              // 创建日期
                              const SizedBox(width: 8),
                              Icon(Icons.add_circle_outline, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.task.createdAt.month}/${widget.task.createdAt.day}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                              // 截止日期
                              if (widget.task.dueDate != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.event, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.task.dueDate!.month}/${widget.task.dueDate!.day}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                              if (widget.task.creatorName != null && widget.task.creatorName!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  widget.task.creatorName!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 编辑按钮
                    if (!widget.isMultiSelectMode)
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: priorityColor.withValues(alpha: 0.6)),
                        onPressed: widget.onEdit,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority) {
    Color color;
    switch (priority) {
      case TaskPriority.high:
        color = const Color(0xFFFF6B8A); // 玫瑰红
        break;
      case TaskPriority.medium:
        color = const Color(0xFFFFB7C5); // 樱花粉
        break;
      case TaskPriority.low:
        color = const Color(0xFF98D8AA); // 薄荷绿
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        Task.getPriorityText(priority),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(TaskCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB7C5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        Task.getCategoryText(category),
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFFF8FAB),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// 划掉效果绘制器
class StrikethroughPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  StrikethroughPainter({
    required this.color,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制斜线划掉效果
    final path = Path();
    // 从左上到右下
    path.moveTo(size.width * 0.1, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrikethroughPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
