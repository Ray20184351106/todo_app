import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_constants.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'screens/user_name_screen.dart';
import 'services/supabase_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase
  await SupabaseService.initialize();

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        // 添加本地化支持
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'), // 中文
          Locale('en', 'US'), // 英文
        ],
        locale: const Locale('zh', 'CN'),
        home: const _InitialScreen(),
      ),
    );
  }
}

/// 初始界面 - 根据是否有用户名决定显示哪个界面
class _InitialScreen extends StatefulWidget {
  const _InitialScreen();

  @override
  State<_InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<_InitialScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool _hasUsername = false;

  @override
  void initState() {
    super.initState();
    _checkUsername();
  }

  Future<void> _checkUsername() async {
    print('_InitialScreen: Checking username...');
    final hasUsername = await _userService.hasUsername();
    print('_InitialScreen: hasUsername = $hasUsername');
    if (mounted) {
      setState(() {
        _hasUsername = hasUsername;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('_InitialScreen: build called, isLoading=$_isLoading, hasUsername=$_hasUsername');
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasUsername) {
      // 已有用户名，显示主界面并初始化数据
      print('_InitialScreen: Showing HomeScreenWrapper');
      return HomeScreenWrapper();
    } else {
      // 没有用户名，显示用户名输入界面
      print('_InitialScreen: Showing UserNameScreen');
      return const UserNameScreen();
    }
  }
}

/// HomeScreen 包装器 - 负责初始化数据
class HomeScreenWrapper extends StatefulWidget {
  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  final TaskProvider _taskProvider = TaskProvider();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print('HomeScreenWrapper: initState called');
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    print('HomeScreenWrapper: Starting provider initialization...');
    try {
      await _taskProvider.initialize();
      print('HomeScreenWrapper: Provider initialization completed');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('HomeScreenWrapper: Initialization error - $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Still show screen even on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreenWrapper: build called, _isInitialized=$_isInitialized');
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    print('HomeScreenWrapper: Returning HomeScreen with provider');
    return ChangeNotifierProvider.value(
      value: _taskProvider,
      child: const HomeScreen(),
    );
  }

  @override
  void dispose() {
    _taskProvider.dispose();
    super.dispose();
  }
}
