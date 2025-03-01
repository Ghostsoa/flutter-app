import 'package:flutter/foundation.dart';

class Logger {
  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void log(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!_enabled) return;

    final time = DateTime.now().toString().split('.').first;
    final tagStr = tag != null ? '[$tag]' : '';

    // 打印基本信息
    debugPrint('$time$tagStr: $message');

    // 如果有错误信息，打印错误
    if (error != null) {
      debugPrint('错误信息: $error');
    }

    // 如果有堆栈信息，打印堆栈
    if (stackTrace != null) {
      debugPrint('堆栈信息:\n$stackTrace');
    }
  }

  static void info(String message, {String? tag}) =>
      log(message, tag: tag ?? 'INFO');

  static void error(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(message, tag: tag ?? 'ERROR', error: error, stackTrace: stackTrace);

  static void network(String message, {String? tag}) =>
      log(message, tag: tag ?? 'NETWORK');
}
