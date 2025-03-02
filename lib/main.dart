import 'package:flutter/material.dart';
import 'core/utils/logger.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/main/screens/main_screen.dart';
import 'features/auth/controllers/auth_controller.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 启用日志
  Logger.enable();

  // 初始化 AuthController
  final authController = AuthController();
  await authController.init();

  runApp(MyApp(authController: authController));
}

class MyApp extends StatelessWidget {
  final AuthController authController;

  const MyApp({
    super.key,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的应用',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.white,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.blue.withOpacity(0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              );
            }
            return const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            );
          }),
        ),
        useMaterial3: true,
      ),
      // 根据登录状态决定初始路由
      initialRoute: authController.currentUser != null ? '/main' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
