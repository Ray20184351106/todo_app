import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// 用户名管理服务
class UserService {
  static final UserService instance = UserService._init();
  factory UserService() => instance;

  UserService._init();

  /// 获取用户名
  Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.usernameKey);
    } catch (e) {
      return null;
    }
  }

  /// 设置用户名
  Future<bool> setUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(AppConstants.usernameKey, username);
    } catch (e) {
      return false;
    }
  }

  /// 检查是否已设置用户名
  Future<bool> hasUsername() async {
    final username = await getUsername();
    return username != null && username.isNotEmpty;
  }

  /// 清除用户名
  Future<bool> clearUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(AppConstants.usernameKey);
    } catch (e) {
      return false;
    }
  }
}
