import 'package:flutter/material.dart';

import '../main.dart'; // 导入 main.dart 以访问 HomeScreenWrapper
import '../services/user_service.dart';

/// 用户选择界面 - 首次启动时显示
class UserNameScreen extends StatefulWidget {
  const UserNameScreen({super.key});

  @override
  State<UserNameScreen> createState() => _UserNameScreenState();
}

class _UserNameScreenState extends State<UserNameScreen> {
  final UserService _userService = UserService();
  String? _selectedUser;

  Future<void> _selectUser(String username) async {
    setState(() {
      _selectedUser = username;
    });

    final success = await _userService.setUsername(username);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreenWrapper()),
      );
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
                  '欢迎来到情侣待办清单',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF8FAB),
                      ),
                ),
                const SizedBox(height: 8),

                // 副标题
                Text(
                  '请选择你是谁~',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 60),

                // 用户选择区域
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 小雷选项（左边）
                    _buildUserOption(
                      image: 'assets/images/user_xiaolei.jpg',
                      name: '小雷',
                      isSelected: _selectedUser == '小雷',
                      onTap: () => _selectUser('小雷'),
                    ),
                    const SizedBox(width: 40),
                    // 芬芬选项（右边）
                    _buildUserOption(
                      image: 'assets/images/user_fenfen.jpg',
                      name: '芬芬',
                      isSelected: _selectedUser == '芬芬',
                      onTap: () => _selectUser('芬芬'),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

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
                          '两个人的甜蜜时光，从今天开始~',
                          style: const TextStyle(
                            color: Color(0xFFFF8FAB),
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

  Widget _buildUserOption({
    required String image,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB7C5) : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB7C5).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Column(
          children: [
            // 头像图片
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFB7C5) : Colors.grey.shade300,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  image,
                  width: 94,
                  height: 94,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 名字
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFF8FAB) : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            // 选择指示器
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB7C5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '已选择',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Text(
                '点击选择',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
