import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

part 'story.g.dart';

@JsonSerializable(explicitToJson: true)
class Story {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String? coverImagePath;
  final String? backgroundImagePath;
  final String opening;
  final String settings;
  @JsonKey(defaultValue: 20)
  final int distillationRounds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    this.coverImagePath,
    this.backgroundImagePath,
    required this.opening,
    required this.settings,
    this.distillationRounds = 20,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoryToJson(this);

  // 导出为完整的 JSON（包含 base64 编码的图片）
  Future<Map<String, dynamic>> toExportJson() async {
    final json = toJson();

    if (coverImagePath != null) {
      final coverFile = File(coverImagePath!);
      if (await coverFile.exists()) {
        final bytes = await coverFile.readAsBytes();
        json['coverImageData'] = base64Encode(bytes);
      }
    }

    if (backgroundImagePath != null) {
      final backgroundFile = File(backgroundImagePath!);
      if (await backgroundFile.exists()) {
        final bytes = await backgroundFile.readAsBytes();
        json['backgroundImageData'] = base64Encode(bytes);
      }
    }

    return json;
  }

  // 从导出的 JSON 创建实例（包含 base64 编码的图片）
  static Future<Story> fromExportJson(
      Map<String, dynamic> json, String storageDir) async {
    String? coverPath;
    String? backgroundPath;

    // 处理封面图片
    if (json.containsKey('coverImageData')) {
      final bytes = base64Decode(json['coverImageData']);
      // 检测文件类型并设置正确的扩展名
      final extension = _detectFileExtension(bytes);
      final fileName = '${const Uuid().v4()}$extension';
      final file = File('$storageDir/$fileName');
      await file.writeAsBytes(bytes);
      coverPath = file.path;
    }

    // 处理背景图片
    if (json.containsKey('backgroundImageData')) {
      final bytes = base64Decode(json['backgroundImageData']);
      // 检测文件类型并设置正确的扩展名
      final extension = _detectFileExtension(bytes);
      final fileName = '${const Uuid().v4()}$extension';
      final file = File('$storageDir/$fileName');
      await file.writeAsBytes(bytes);
      backgroundPath = file.path;
    }

    // 确保 distillationRounds 有默认值
    final Map<String, dynamic> storyJson = Map<String, dynamic>.from(json);
    if (!storyJson.containsKey('distillationRounds')) {
      storyJson['distillationRounds'] = 20;
    }

    return Story(
      id: storyJson['id'],
      title: storyJson['title'],
      description: storyJson['description'],
      categoryId: storyJson['categoryId'],
      coverImagePath: coverPath ?? storyJson['coverImagePath'],
      backgroundImagePath: backgroundPath ?? storyJson['backgroundImagePath'],
      opening: storyJson['opening'],
      settings: storyJson['settings'],
      distillationRounds: storyJson['distillationRounds'],
      createdAt: DateTime.parse(storyJson['createdAt']),
      updatedAt: DateTime.parse(storyJson['updatedAt']),
    );
  }

  // 检测文件类型并返回对应的扩展名
  static String _detectFileExtension(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 && // G
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46) {
      // F
      return '.gif';
    }
    // 默认使用 jpg
    return '.jpg';
  }
}
