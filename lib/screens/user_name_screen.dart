import 'package:flutter/material.dart';

import '../main.dart'; // 导入 main.dart 以访问 HomeScreenWrapper
import '../services/user_service.dart';

/// 用户名输入界面 - 首次启动时显示
class UserNameScreen extends StatefulWidget {
  const UserNameScreen({super.key});

  @override
  State<UserNameScreen> createState() => _UserNameScreenState();
}

class _UserNameScreenState extends State<UserNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitUsername() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _nameController.text.trim();
      final success = await _userService.setUsername(username);

      if (success && mounted) {
        // 保存成功，导航到主界面（使用 HomeScreenWrapper 以初始化 TaskProvider）
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreenWrapper()),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = '保存用户名失败，请重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '发生错误: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7), // 粉白背景
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Hello Kitty 信封图片
                Image.asset(
                  'assets/images/kitty_letter.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 24),

                // 标题
                Text(
                  '欢迎来到待办清单',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF8FAB),
                      ),
                ),
                const SizedBox(height: 8),

                // 副标题
                Text(
                  '请输入您的名字开始使用~',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 48),

                // 表单
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 用户名输入框
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '您的名字',
                          hintText: '例如: 小芬',
                          prefixIcon: const Icon(Icons.person, color: Color(0xFFFFB7C5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFB7C5), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入您的名字';
                          }
                          if (value.trim().length < 2) {
                            return '名字至少需要 2 个字符';
                          }
                          if (value.trim().length > 20) {
                            return '名字不能超过 20 个字符';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitUsername(),
                      ),
                      const SizedBox(height: 16),

                      // 错误提示
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF6B8A).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFFF6B8A), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Color(0xFFFF6B8A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 提交按钮
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitUsername,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB7C5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '开始使用',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 提示信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB7C5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB7C5).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFFF8FAB), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '您的名字将显示在您创建的任务上',
                          style: TextStyle(
                            color: const Color(0xFFFF8FAB),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
