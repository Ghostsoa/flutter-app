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
              seedColor: Colors.blue,
              background: Colors.white,
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
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
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              background: const Color(0xFF1A1A1A),
              surface: const Color(0xFF2C2C2C),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF1A1A1A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardTheme(
              color: const Color(0xFF2C2C2C),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.3),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF2C2C2C),
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.3),
              surfaceTintColor: Colors.transparent,
              indicatorColor: Colors.blue.withOpacity(0.15),
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
            dialogTheme: const DialogTheme(
              backgroundColor: Color(0xFF2C2C2C),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF2C2C2C),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFF3C3C3C),
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
