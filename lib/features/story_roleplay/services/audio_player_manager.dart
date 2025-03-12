import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/network/api/tts_api.dart';
import '../../../core/utils/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../data/local/shared_prefs/voice_setting_storage.dart';
import '../../../data/models/voice_setting.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  error,
}

// 自定义MP3音频源
class MP3AudioSource extends StreamAudioSource {
  final Uint8List audioData;
  final int sampleRate;

  MP3AudioSource(this.audioData, {this.sampleRate = 32000}) {
    // 调试：检查音频数据
    if (audioData.length > 10) {
      final header = audioData
          .sublist(0, 10)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      Logger.info('MP3音频源头部数据: $header');
    }

    // 验证MP3头部标识
    if (audioData.length > 2) {
      final isValidMp3 = audioData[0] == 0xFF && (audioData[1] & 0xE0) == 0xE0;
      Logger.info('是否为有效的MP3格式: $isValidMp3');
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= audioData.length;

    Logger.info('请求音频数据片段: $start 到 $end (总长度: ${audioData.length})');

    return StreamAudioResponse(
      sourceLength: audioData.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(audioData.sublist(start, end)),
      contentType: 'audio/mpeg', // MP3的MIME类型
    );
  }
}

class AudioPlayerManager {
  final TTSApi _ttsApi;
  final _audioPlayer = AudioPlayer();
  final _playbackStateNotifier =
      ValueNotifier<PlaybackState>(PlaybackState.idle);
  String? _currentAudioId;
  String? _currentText;
  late Directory _cacheDir;

  AudioPlayerManager() : _ttsApi = TTSApi();

  ValueNotifier<PlaybackState> get playbackState => _playbackStateNotifier;
  String? get currentAudioId => _currentAudioId;
  String? get currentText => _currentText;

  Future<void> init() async {
    await _ttsApi.init();

    // 初始化缓存目录
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playbackStateNotifier.value = PlaybackState.idle;
        _currentAudioId = null;
        _currentText = null;
      }
    });
  }

  // 生成音频ID
  String _generateAudioId(String text, VoiceSetting setting) {
    final content =
        '${text}_${setting.voiceId}_${setting.speed}_${setting.vol}_${setting.pitch}_${setting.emotion}';
    return md5.convert(utf8.encode(content)).toString();
  }

  // 根据audioId获取缓存文件路径
  String _getCacheFilePath(String audioId) {
    return '${_cacheDir.path}/$audioId.mp3';
  }

  // 从缓存中获取音频文件
  Future<File?> _getAudioFromCache(String audioId) async {
    final file = File(_getCacheFilePath(audioId));
    if (await file.exists()) {
      Logger.info('从缓存中获取音频: $audioId');
      return file;
    }
    return null;
  }

  // 将音频保存到缓存
  Future<File> _saveAudioToCache(String audioId, Uint8List audioData) async {
    final file = File(_getCacheFilePath(audioId));
    await file.writeAsBytes(audioData);
    Logger.info('保存音频到缓存: $audioId, 大小: ${audioData.length} 字节');

    // 保存后检查并清理过期缓存
    await _cleanupOldCache();

    return file;
  }

  // 清理过期缓存，保持缓存数量在设置的限制内
  Future<void> _cleanupOldCache() async {
    try {
      // 获取当前设置的缓存限制
      final setting = await VoiceSettingStorage.getCurrentSetting();
      final cacheLimit = setting.cacheLimit;

      // 如果缓存限制为0，则不限制缓存数量
      if (cacheLimit <= 0) {
        return;
      }

      // 获取所有缓存文件
      final dir = Directory(_cacheDir.path);
      if (!await dir.exists()) {
        return;
      }

      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.mp3'))
          .toList();

      // 按修改时间排序，最旧的在前面
      files.sort((a, b) {
        final aTime = (a as File).lastModifiedSync();
        final bTime = (b as File).lastModifiedSync();
        return aTime.compareTo(bTime);
      });

      // 如果文件数量超过限制，删除最旧的文件
      if (files.length > cacheLimit) {
        final filesToDelete = files.sublist(0, files.length - cacheLimit);
        Logger.info(
            '缓存文件数量(${files.length})超过限制($cacheLimit)，删除${filesToDelete.length}个旧文件');

        for (var entity in filesToDelete) {
          final file = entity as File;
          final fileName = file.path.split('/').last;
          try {
            await file.delete();
            Logger.info('删除缓存文件: $fileName');
          } catch (e) {
            Logger.error('删除缓存文件失败: $fileName', error: e);
          }
        }
      }
    } catch (e) {
      Logger.error('清理过期缓存失败', error: e);
    }
  }

  // 清除所有缓存的音频文件
  Future<void> clearCache() async {
    try {
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
        Logger.info('已清除所有缓存的音频文件');
      }
    } catch (e) {
      Logger.error('清除缓存失败', error: e);
      rethrow;
    }
  }

  // 获取当前缓存的音频文件数量
  Future<int> getCachedAudioCount() async {
    try {
      final dir = Directory(_cacheDir.path);
      if (!await dir.exists()) {
        return 0;
      }

      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.mp3'))
          .length;

      return files;
    } catch (e) {
      Logger.error('获取缓存数量失败', error: e);
      return 0;
    }
  }

  // 获取当前缓存占用的空间（字节）
  Future<int> getCachedAudioSize() async {
    try {
      final dir = Directory(_cacheDir.path);
      if (!await dir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (var entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      Logger.error('获取缓存大小失败', error: e);
      return 0;
    }
  }

  Future<void> playText(String text) async {
    if (_playbackStateNotifier.value == PlaybackState.loading) {
      return;
    }

    try {
      // 如果正在播放同一段文本，就停止播放
      if (_currentText == text &&
          _playbackStateNotifier.value == PlaybackState.playing) {
        await stop();
        return;
      }

      // 如果正在播放其他文本，先停止
      if (_playbackStateNotifier.value == PlaybackState.playing) {
        await _audioPlayer.stop();
      }

      // 获取文本对应的audioId
      final setting = await VoiceSettingStorage.getCurrentSetting();
      final audioId = _generateAudioId(text, setting);

      // 检查缓存中是否存在
      File? audioFile = await _getAudioFromCache(audioId);

      // 设置当前文本和音频ID
      _currentText = text;
      _currentAudioId = audioId;

      if (audioFile != null) {
        Logger.info('使用缓存的音频播放: $audioId');
        // 播放音频文件
        await _audioPlayer.setFilePath(audioFile.path);
        _playbackStateNotifier.value = PlaybackState.playing;
        await _audioPlayer.play();
      } else {
        // 如果缓存中不存在，则请求API
        Logger.info('缓存中不存在音频: $audioId, 正在请求API');
        _playbackStateNotifier.value = PlaybackState.loading;
        
        final response = await _ttsApi.convertToSpeech(text);
        audioFile = await _saveAudioToCache(audioId, response.audioData);
        await _audioPlayer.setFilePath(audioFile.path);
        _playbackStateNotifier.value = PlaybackState.playing;
        await _audioPlayer.play();
      }
    } catch (e) {
      Logger.error('播放失败', error: e);
      _playbackStateNotifier.value = PlaybackState.error;
      _currentAudioId = null;
      _currentText = null;
      rethrow;
    }
  }

  Future<void> playTextWithAudioId(String text, String audioId) async {
    if (_playbackStateNotifier.value == PlaybackState.loading) {
      return;
    }

    try {
      // 如果正在播放同一段文本，就停止播放
      if (_currentText == text &&
          _playbackStateNotifier.value == PlaybackState.playing) {
        await stop();
        return;
      }

      // 如果正在播放其他文本，先停止
      if (_playbackStateNotifier.value == PlaybackState.playing) {
        await _audioPlayer.stop();
      }

      // 检查缓存中是否存在
      File? audioFile = await _getAudioFromCache(audioId);

      // 设置当前文本和音频ID
      _currentText = text;
      _currentAudioId = audioId;

      if (audioFile != null) {
        Logger.info('使用缓存的音频播放: $audioId');
        // 播放音频文件
        await _audioPlayer.setFilePath(audioFile.path);
        _playbackStateNotifier.value = PlaybackState.playing;
        await _audioPlayer.play();
      } else {
        // 如果缓存中不存在，则回退到普通的播放方法
        Logger.info('缓存中不存在音频: $audioId, 回退到普通播放');
        await playText(text);
      }
    } catch (e) {
      Logger.error('播放失败', error: e);
      _playbackStateNotifier.value = PlaybackState.error;
      _currentAudioId = null;
      _currentText = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_playbackStateNotifier.value == PlaybackState.playing) {
      await _audioPlayer.stop();
      _playbackStateNotifier.value = PlaybackState.idle;
      _currentAudioId = null;
      _currentText = null;
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
