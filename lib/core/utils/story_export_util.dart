import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../data/models/story.dart';
import '../../data/local/shared_prefs/story_storage.dart';
import 'logger.dart';
import 'package:uuid/uuid.dart';

class StoryExportUtil {
  static Future<void> exportStory(Story story) async {
    try {
      // 转换为导出格式
      final exportData = await story.toExportJson();
      final jsonString = jsonEncode(exportData);
      final bytes = utf8.encode(jsonString);

      // 选择保存位置
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出故事',
        fileName: '${story.title}(故事).json',
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: bytes,
      );

      if (result != null) {
        Logger.info('故事导出成功: ${story.title}');
      }
    } catch (e) {
      Logger.error('故事导出失败: $e');
      rethrow;
    }
  }

  static Future<void> exportAllStories(StoryStorage storage) async {
    try {
      final stories = await storage.getStories();
      final exportDataList = await Future.wait(
        stories.map((story) => story.toExportJson()),
      );

      final jsonString = jsonEncode({
        'version': '1.0.0',
        'stories': exportDataList,
      });

      final bytes = utf8.encode(jsonString);

      // 选择保存位置
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出所有故事',
        fileName:
            'stories_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: bytes,
      );

      if (result != null) {
        Logger.info('所有故事导出成功，共 ${stories.length} 个故事');
      }
    } catch (e) {
      Logger.error('导出所有故事失败: $e');
      rethrow;
    }
  }

  static Future<List<Story>> importStories(StoryStorage storage) async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '导入故事',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      // 获取存储目录
      final appDir = await getApplicationDocumentsDirectory();
      final storiesDir = path.join(appDir.path, 'stories');

      // 确保存储目录存在
      final dir = Directory(storiesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 读取文件内容
      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      // 处理单个故事或故事列表
      if (jsonData is Map && jsonData.containsKey('stories')) {
        // 导入故事列表
        final storiesList =
            (jsonData['stories'] as List).cast<Map<String, dynamic>>();
        final stories = await Future.wait(
          storiesList.map((storyJson) {
            // 生成新的ID
            storyJson['id'] = const Uuid().v4();
            return Story.fromExportJson(storyJson, storiesDir);
          }),
        );

        // 保存到本地存储
        for (final story in stories) {
          await storage.saveStory(story);
        }

        Logger.info('成功导入 ${stories.length} 个故事');
        return stories;
      } else {
        // 导入单个故事
        // 生成新的ID
        jsonData['id'] = const Uuid().v4();
        final story = await Story.fromExportJson(jsonData, storiesDir);
        await storage.saveStory(story);
        Logger.info('成功导入故事: ${story.title}');
        return [story];
      }
    } catch (e) {
      Logger.error('导入故事失败: $e');
      rethrow;
    }
  }
}
