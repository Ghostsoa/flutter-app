import 'package:flutter/material.dart';
import 'core/utils/logger.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/main/screens/main_screen.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 启用日志
  Logger.enable();

  // 初始化 AuthController
  final authController = AuthController();
  await authController.init();

  // 初始化主题
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(MyApp(
    authController: authController,
    themeProvider: themeProvider,
  ));
}

class MyApp extends StatelessWidget {
  final AuthController authController;
  final ThemeProvider themeProvider;

  const MyApp({
    super.key,
    required this.authController,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        return MaterialApp(
          title: '我的应用',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.themeColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.themeColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          // 根据登录状态决定初始路由
          initialRoute: authController.currentUser != null ? '/main' : '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/main': (context) => const MainScreen(),
          },
        );
      },
    );
  }
}
