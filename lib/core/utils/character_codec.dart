import 'dart:convert';
import 'dart:io';
import '../../data/models/character.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class CharacterCodec {
  static const String fileExtension = '.json';
  static const String magicNumber = 'WYYCHAR'; // 文件魔数，用于标识文件类型
  static const int version = 1; // 版本号，用于后续格式升级
  static const _uuid = Uuid();

  /// 将角色数据编码为JSON
  static String encode(Character character) {
    // 创建不包含敏感信息的角色数据副本
    final exportData = character.copyWith(
      id: '', // 不导出ID
      coverImageUrl: null, // 不导出封面图片URL
    );

    // 将角色数据转换为JSON
    final jsonData = exportData.toJson();
    // 移除敏感字段
    jsonData.remove('id');
    jsonData.remove('coverImageUrl');

    // 读取并编码图片数据
    String? imageData;
    String? imageExtension;
    if (character.coverImageUrl != null) {
      try {
        final file = File(character.coverImageUrl!);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          imageData = base64Encode(bytes);
          imageExtension = path.extension(character.coverImageUrl!);
        }
      } catch (e) {
        print('读取图片失败：$e');
      }
    }

    // 创建元数据
    final metadata = {
      'magic': magicNumber,
      'version': version,
      'timestamp': DateTime.now().toIso8601String(),
      'hasImage': imageData != null,
      'imageExtension': imageExtension,
    };

    // 合并元数据、角色数据和图片数据
    final fullData = {
      'metadata': metadata,
      'character': jsonData,
      'imageData': imageData,
    };

    // 转换为格式化的JSON字符串
    return const JsonEncoder.withIndent('  ').convert(fullData);
  }

  /// 解码JSON数据为角色对象
  static Character? decode(String jsonString) {
    try {
      // 解析JSON
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // 验证元数据
      final metadata = data['metadata'] as Map<String, dynamic>;
      if (metadata['magic'] != magicNumber) {
        throw const FormatException('无效的文件格式');
      }

      // 验证版本号
      final version = metadata['version'] as int;
      if (version > CharacterCodec.version) {
        throw FormatException('不支持的版本号：$version');
      }

      // 解析角色数据
      final characterData = data['character'] as Map<String, dynamic>;

      // 处理图片数据
      String? coverImageUrl;
      if (metadata['hasImage'] == true && data['imageData'] != null) {
        try {
          final imageBytes = base64Decode(data['imageData'] as String);
          final imageExtension =
              metadata['imageExtension'] as String? ?? '.jpg';
          final tempDir = Directory.systemTemp;
          final imageFile =
              File('${tempDir.path}/${_uuid.v4()}$imageExtension');
          imageFile.writeAsBytesSync(imageBytes);
          coverImageUrl = imageFile.path;
        } catch (e) {
          print('解码图片失败：$e');
        }
      }

      // 添加新的id和图片路径
      characterData['id'] = _uuid.v4();
      characterData['coverImageUrl'] = coverImageUrl;
      return Character.fromJson(characterData);
    } catch (e) {
      return null;
    }
  }

  /// 验证文件名是否符合格式要求
  static bool isValidFileName(String fileName) {
    return fileName.toLowerCase().endsWith(fileExtension);
  }

  /// 生成导出文件名
  static String generateFileName(String characterName) {
    // 替换不合法的文件名字符
    final safeName = characterName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$safeName$fileExtension';
  }
}
