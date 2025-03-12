import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../dio/dio_client.dart';
import '../../../data/models/voice_setting.dart';
import '../../../data/local/shared_prefs/voice_setting_storage.dart';
import '../../utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

class TTSResponse {
  final Uint8List audioData;
  final String audioId;
  final int audioLength;
  final int sampleRate;
  final int bitrate;
  final String format;

  TTSResponse({
    required this.audioData,
    required this.audioId,
    required this.audioLength,
    required this.sampleRate,
    required this.bitrate,
    required this.format,
  });
}

class TTSApi {
  static const String _baseUrl = 'https://cc.xiaoyi.live';
  late final DioClient _client;
  late final Directory _cacheDir;
  late final SharedPreferences _prefs;
  static const String _audioListKey = 'cached_audio_list';

  TTSApi();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _client = DioClient(_baseUrl, _prefs);
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    await _cleanupCache();
  }

  // 生成音频ID
  String _generateAudioId(String text, VoiceSetting setting) {
    final content =
        '${text}_${setting.voiceId}_${setting.speed}_${setting.vol}_${setting.pitch}_${setting.emotion}';
    return md5.convert(utf8.encode(content)).toString();
  }

  // 清理过期缓存
  Future<void> _cleanupCache() async {
    final setting = await VoiceSettingStorage.getCurrentSetting();
    final List<String> audioList = _prefs.getStringList(_audioListKey) ?? [];

    if (audioList.length > setting.cacheLimit) {
      // 删除旧的音频文件
      final toRemove =
          audioList.sublist(0, audioList.length - setting.cacheLimit);
      for (final audioId in toRemove) {
        final file = File('${_cacheDir.path}/$audioId.pcm');
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 更新缓存列表
      audioList.removeRange(0, audioList.length - setting.cacheLimit);
      await _prefs.setStringList(_audioListKey, audioList);
    }
  }

  // 转换文本为语音
  Future<TTSResponse> convertToSpeech(String text,
      {VoiceSetting? setting}) async {
    try {
      setting ??= await VoiceSettingStorage.getCurrentSetting();
      final audioId = _generateAudioId(text, setting);

      // 直接发送请求
      final response = await _client.post(
        '/api/v1/tts/convert',
        data: {
          'text': text,
          'voice_setting': {
            'voice_id': setting.voiceId,
            'speed': setting.speed,
            'vol': setting.vol,
            'pitch': setting.pitch,
            'emotion': setting.emotion,
          },
        },
      );

      // 添加调试日志
      Logger.info('响应数据结构: ${response.data.runtimeType}');

      // 处理响应数据
      Map<String, dynamic> responseMap;
      if (response.data is String) {
        // 如果响应是字符串，尝试解析为JSON
        try {
          responseMap = json.decode(response.data as String);
          Logger.info('成功将字符串响应解析为JSON');
        } catch (e) {
          Logger.error('无法将响应解析为JSON', error: e);
          throw Exception('无法解析服务器响应');
        }
      } else if (response.data is Map<String, dynamic>) {
        // 如果已经是Map，直接使用
        responseMap = response.data as Map<String, dynamic>;
      } else {
        Logger.error('响应数据类型不支持: ${response.data.runtimeType}');
        throw Exception('不支持的响应数据类型');
      }

      Logger.info('处理后的响应数据: $responseMap');

      if (responseMap['data'] == null) {
        Logger.error('响应中没有data字段');
        throw Exception('响应中没有data字段');
      }

      if (responseMap['data']['audio'] == null) {
        Logger.error('响应中没有audio字段');
        throw Exception('响应中没有audio字段');
      }

      // 直接获取音频数据
      final audioHex = responseMap['data']['audio'] as String;
      Logger.info('收到的音频数据长度: ${audioHex.length}');

      // 解析十六进制编码的MP3数据
      Uint8List audioData;
      try {
        // 确保字符串长度是偶数
        String processedHex = audioHex;
        if (audioHex.length % 2 != 0) {
          processedHex = audioHex.substring(0, audioHex.length - 1);
          Logger.info('调整后的音频数据长度: ${processedHex.length}');
        }

        // 使用更高效的方法解析十六进制字符串
        final bytes = <int>[];
        for (int i = 0; i < processedHex.length; i += 2) {
          final hexPair = processedHex.substring(i, i + 2);
          try {
            final byte = int.parse(hexPair, radix: 16);
            bytes.add(byte);
          } catch (e) {
            Logger.error('无效的十六进制对: $hexPair 在位置 $i');
            // 跳过无效的十六进制对，继续处理
          }
        }

        audioData = Uint8List.fromList(bytes);
        Logger.info('十六进制解析成功，数据长度: ${audioData.length}');

        // 调试：输出前几个字节，检查MP3头部
        if (audioData.length > 10) {
          final header = audioData
              .sublist(0, 10)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(' ');
          Logger.info('MP3头部数据: $header');
        }
      } catch (e) {
        Logger.error('音频数据解析失败', error: e);
        throw Exception('音频数据解析失败: $e');
      }

      // 获取extra_info
      final extraInfo = responseMap['extra_info'];

      // 返回结果
      return TTSResponse(
        audioData: audioData,
        audioId: audioId,
        audioLength: int.parse(extraInfo['audio_length']?.toString() ?? '0'),
        sampleRate:
            int.parse(extraInfo['audio_sample_rate']?.toString() ?? '32000'),
        bitrate: int.parse(extraInfo['audio_bitrate']?.toString() ?? '128000'),
        format: extraInfo['audio_format']?.toString() ?? 'mp3',
      );
    } catch (e) {
      Logger.error('语音合成失败', error: e);
      rethrow;
    }
  }

  // 清除所有缓存
  Future<void> clearCache() async {
    try {
      final dir = Directory(_cacheDir.path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      await _prefs.remove(_audioListKey);
    } catch (e) {
      Logger.error('清除缓存失败', error: e);
      rethrow;
    }
  }
}
