import '../dio/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_api.dart';
import '../../../data/models/announcement.dart';

class LotteryApi {
  static const String signIn = '/api/v1/sign-in';
  static const String draw = '/api/v1/lottery/draw';
  static const String winners = '/api/v1/lottery/winners';
  static const String announcements = '/api/v1/announcements';
  static const String announcementsList = '/api/v1/announcements/list';

  static LotteryApi? _instance;
  final DioClient _client;

  LotteryApi._internal(this._client);

  static Future<LotteryApi> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      final dioClient = DioClient(AuthApi.baseUrl, prefs);
      _instance = LotteryApi._internal(dioClient);
    }
    return _instance!;
  }

  Future<Map<String, dynamic>> signInDaily() async {
    try {
      final response = await _client.post(signIn);
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];
      if (data == null) {
        throw Exception('今日已签到');
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      if (e.toString().contains(
          "type 'Null' is not a subtype of type 'Map<String, dynamic>'")) {
        throw Exception('今日已签到');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> drawLottery() async {
    try {
      final response = await _client.post(draw);
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];
      if (data == null) {
        throw Exception('抽奖次数已用完');
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      if (e.toString().contains('recordnot found')) {
        throw Exception('抽奖次数已用完');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWinners() async {
    final response = await _client.get(winners);
    final responseData = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(responseData['data']);
  }

  Future<({bool needUpdate, Announcement? announcement})>
      getLatestAnnouncement({
    int? currentId,
  }) async {
    final response = await _client.get(
      announcements,
      queryParameters: currentId != null ? {'current_id': currentId} : null,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'];
    if (data == null) {
      return (needUpdate: false, announcement: null);
    }

    final needUpdate = data['need_update'] as bool;
    if (!needUpdate) {
      return (needUpdate: false, announcement: null);
    }

    return (
      needUpdate: true,
      announcement: Announcement.fromJson(data['announcement']),
    );
  }

  Future<
      ({
        int total,
        List<Announcement> items,
        int page,
        int pageSize,
      })> getAnnouncementsList({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _client.get(
      announcementsList,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((item) => Announcement.fromJson(item))
        .toList();

    return (
      total: data['total'] as int,
      items: items,
      page: data['page'] as int,
      pageSize: data['page_size'] as int,
    );
  }
}
