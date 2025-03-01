import '../dio/dio_client.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/api_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';

class WalletApi {
  static const String balance = '/api/v1/balance';
  static const String transactions = '/api/v1/transactions';
  static const String apiLogs = '/api/v1/api-logs';

  static WalletApi? _instance;
  final DioClient _client;

  WalletApi._internal(this._client);

  static Future<WalletApi> getInstance() async {
    if (_instance == null) {
      Logger.info('初始化 WalletApi');
      final prefs = await SharedPreferences.getInstance();
      final dioClient = DioClient('https://cc.xiaoyi.live', prefs);
      _instance = WalletApi._internal(dioClient);
      Logger.info('WalletApi 初始化完成');
    }
    return _instance!;
  }

  Future<double> getBalance() async {
    try {
      Logger.info('请求余额接口：$balance');
      final response = await _client.get(balance);
      Logger.info('余额接口响应：${response.data}');
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;
      return data['balance'].toDouble();
    } catch (e, stackTrace) {
      Logger.error(
        '请求余额接口失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<({int total, List<Transaction> items})> getTransactions({
    required int page,
    required int pageSize,
    TransactionType? type,
  }) async {
    final response = await _client.get(
      transactions,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (type != null) 'transaction_type': type.name,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((item) => Transaction.fromJson(item))
        .toList();

    return (
      total: (data['total'] as num).toInt(),
      items: items,
    );
  }

  Future<({int total, List<ApiLog> items})> getApiLogs({
    required int page,
    required int pageSize,
    String? endpoint,
  }) async {
    final response = await _client.get(
      apiLogs,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (endpoint != null) 'endpoint': endpoint,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final items =
        (data['items'] as List).map((item) => ApiLog.fromJson(item)).toList();

    return (
      total: (data['total'] as num).toInt(),
      items: items,
    );
  }
}
