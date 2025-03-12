import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../models/group_chat.dart';

class GroupChatRepository {
  static const String _groupsDir = 'groups';
  static GroupChatRepository? _instance;
  late final Directory _baseDir;

  GroupChatRepository._();

  static Future<GroupChatRepository> create() async {
    if (_instance != null) return _instance!;

    final repository = GroupChatRepository._();
    await repository._init();
    _instance = repository;
    return repository;
  }

  Future<void> _init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory(path.join(appDir.path, _groupsDir));
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }
  }

  Future<String> processImage(File file, {int maxSize = 800}) async {
    final bytes = await file.readAsBytes();

    // 检测是否是GIF文件
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 && // G
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46) {
      // F
      // 如果是GIF，直接返回base64编码
      return base64Encode(bytes);
    }

    // 处理其他图片格式
    final image = img.decodeImage(bytes);
    if (image == null) throw '无法解码图片';

    double width = image.width.toDouble();
    double height = image.height.toDouble();

    if (width > maxSize || height > maxSize) {
      if (width > height) {
        height = height * (maxSize.toDouble() / width);
        width = maxSize.toDouble();
      } else {
        width = width * (maxSize.toDouble() / height);
        height = maxSize.toDouble();
      }
    }

    final resized = img.copyResize(
      image,
      width: width.round(),
      height: height.round(),
      interpolation: img.Interpolation.linear,
    );

    // 根据原始图片格式选择编码方式
    List<int> encoded;
    if (path.extension(file.path).toLowerCase() == '.png') {
      encoded = img.encodePng(resized, level: 6);
    } else {
      encoded = img.encodeJpg(resized, quality: 92);
    }

    return base64Encode(encoded);
  }

  Future<void> saveGroupChat(GroupChat groupChat) async {
    final file = File(path.join(_baseDir.path, '${groupChat.id}.json'));

    // 将群聊数据转换为JSON
    final json = groupChat.toJson();

    // 保存文件
    await file.writeAsString(jsonEncode(json));
  }

  Future<List<GroupChat>> getAllGroupChats() async {
    final groups = <GroupChat>[];

    try {
      await for (final file in _baseDir.list()) {
        if (file is File && path.extension(file.path) == '.json') {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            groups.add(GroupChat.fromJson(json));
          } catch (e) {
            print('读取群聊文件失败: $e');
          }
        }
      }
    } catch (e) {
      print('获取群聊列表失败: $e');
    }

    return groups;
  }

  Future<void> deleteGroupChat(String id) async {
    final file = File(path.join(_baseDir.path, '$id.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
