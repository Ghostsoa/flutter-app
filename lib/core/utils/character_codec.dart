import 'dart:convert';
import 'dart:io';
import '../../data/models/character.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
  static Future<Character?> decode(String jsonString) async {
    try {
      // 解析JSON
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final charactersDir = Directory(path.join(appDir.path, 'characters'));
      if (!await charactersDir.exists()) {
        await charactersDir.create(recursive: true);
      }

      // 处理本地导出的格式
      if (data['metadata'] != null && data['character'] != null) {
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
            final imageFile = File(
                path.join(charactersDir.path, '${_uuid.v4()}$imageExtension'));
            await imageFile.writeAsBytes(imageBytes);
            coverImageUrl = imageFile.path;
          } catch (e) {
            print('解码图片失败：$e');
          }
        }

        // 添加新的id和图片路径
        characterData['id'] = _uuid.v4();
        characterData['coverImageUrl'] = coverImageUrl;
        return Character.fromJson(characterData);
      }

      // 处理大厅格式
      // 如果有coverImageData，转换为coverImageUrl
      if (data['coverImageData'] != null) {
        try {
          final base64Data = data['coverImageData'] as String;
          // 处理可能包含 data:image/jpeg;base64, 前缀的情况
          final base64String =
              base64Data.contains(',') ? base64Data.split(',')[1] : base64Data;

          final imageFile =
              File(path.join(charactersDir.path, '${_uuid.v4()}.jpg'));
          await imageFile.writeAsBytes(base64Decode(base64String));
          data['coverImageUrl'] = imageFile.path;
        } catch (e) {
          print('解码图片失败：$e');
        }
      }

      // 处理 modelConfig
      if (data['modelConfig'] != null) {
        final modelConfig = data['modelConfig'] as Map<String, dynamic>;
        // 将 modelConfig 中的字段提升到顶层
        data.addAll(modelConfig);
        data.remove('modelConfig');
      }

      // 处理 style
      if (data['style'] != null) {
        final style = data['style'] as Map<String, dynamic>;
        // 将 style 中的字段提升到顶层
        data.addAll(style);
        data.remove('style');
      }

      // 添加新的id
      data['id'] = _uuid.v4();
      return Character.fromJson(data);
    } catch (e) {
      print('解码失败：$e');
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
