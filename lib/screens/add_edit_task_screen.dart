import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedCategory = TaskCategory.other;
  DateTime? _selectedDueDate;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task != null;

    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');

    if (_isEditing && widget.task != null) {
      _selectedPriority = widget.task!.priority;
      _selectedCategory = widget.task!.category;
      _selectedDueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑任务' : '添加任务'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildPrioritySelector(),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildDueDateSelector(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: '任务标题 *',
        hintText: '输入任务标题',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB7C5), width: 2),
        ),
        prefixIcon: const Icon(Icons.title, color: Color(0xFFFFB7C5)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入任务标题';
        }
        return null;
      },
      maxLength: 100,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: '任务描述',
        hintText: '输入任务描述（可选）',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB7C5), width: 2),
        ),
        prefixIcon: const Icon(Icons.description, color: Color(0xFFFFB7C5)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: 3,
      maxLength: 500,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '优先级',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskPriority.values.map((priority) {
            return ChoiceChip(
              label: Text(Task.getPriorityText(priority)),
              selected: _selectedPriority == priority,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                }
              },
              backgroundColor: _getPriorityColor(priority).withOpacity(0.1),
              selectedColor: _getPriorityColor(priority).withOpacity(0.3),
              labelStyle: TextStyle(
                color: _getPriorityColor(priority),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskCategory.values.map((category) {
            return ChoiceChip(
              label: Text(Task.getCategoryText(category)),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
              backgroundColor: const Color(0xFFFFB7C5).withOpacity(0.1),
              selectedColor: const Color(0xFFFFB7C5).withOpacity(0.3),
              labelStyle: const TextStyle(
                color: Color(0xFFFF8FAB),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '截止日期（可选）',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDueDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFB7C5).withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFFFB7C5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDueDate == null
                        ? '选择截止日期'
                        : DateFormat('yyyy年MM月dd日').format(_selectedDueDate!),
                    style: TextStyle(
                      color: _selectedDueDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                if (_selectedDueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFFFF8FAB)),
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFFFB7C5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(_isEditing ? '保存修改' : '创建任务', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFFFB7C5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('取消', style: TextStyle(fontSize: 16, color: Color(0xFFFF8FAB))),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task.create(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        dueDate: _selectedDueDate,
      );

      final taskProvider = context.read<TaskProvider>();

      if (_isEditing && widget.task != null) {
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          category: _selectedCategory,
          dueDate: _selectedDueDate,
        );
        taskProvider.updateTask(updatedTask);
      } else {
        taskProvider.addTask(task);
      }

      Navigator.of(context).pop();
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFF6B8A); // 玫瑰红
      case TaskPriority.medium:
        return const Color(0xFFFFB7C5); // 樱花粉
      case TaskPriority.low:
        return const Color(0xFF98D8AA); // 薄荷绿
    }
  }
}