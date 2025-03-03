import 'package:json_annotation/json_annotation.dart';

part 'character.g.dart';

@JsonSerializable()
class CharacterStatus {
  final String name;
  final String type; // 'number' 或 'text'
  final String? value;
  final double? numberValue;

  CharacterStatus({
    required this.name,
    required this.type,
    this.value,
    this.numberValue,
  });

  factory CharacterStatus.fromJson(Map<String, dynamic> json) =>
      _$CharacterStatusFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterStatusToJson(this);
}

@JsonSerializable()
class Character {
  final String id;
  final String name;
  final String description;
  final String? coverImageUrl;
  final String? userSetting; // 用户设定
  final String? greeting; // 开场白
  final bool useMarkdown; // 是否使用Markdown格式化
  final bool hasStatus; // 是否启用状态
  final List<CharacterStatus> statusList; // 状态列表

  // 聊天界面样式设置
  final double backgroundOpacity; // 背景透明度
  final String userBubbleColor; // 用户气泡颜色
  final String aiBubbleColor; // AI气泡颜色
  final String userTextColor; // 用户文本颜色
  final String aiTextColor; // AI文本颜色

  Character({
    required this.id,
    required this.name,
    required this.description,
    this.coverImageUrl,
    this.userSetting,
    this.greeting,
    this.useMarkdown = false,
    this.hasStatus = false,
    this.statusList = const [],
    this.backgroundOpacity = 0.5,
    this.userBubbleColor = '#2196F3', // 默认蓝色
    this.aiBubbleColor = '#1A1A1A', // 默认深灰色
    this.userTextColor = '#FFFFFF', // 默认白色
    this.aiTextColor = '#FFFFFF', // 默认白色
  });

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterToJson(this);

  Character copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImageUrl,
    String? userSetting,
    String? greeting,
    bool? useMarkdown,
    bool? hasStatus,
    List<CharacterStatus>? statusList,
    double? backgroundOpacity,
    String? userBubbleColor,
    String? aiBubbleColor,
    String? userTextColor,
    String? aiTextColor,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      userSetting: userSetting ?? this.userSetting,
      greeting: greeting ?? this.greeting,
      useMarkdown: useMarkdown ?? this.useMarkdown,
      hasStatus: hasStatus ?? this.hasStatus,
      statusList: statusList ?? this.statusList,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      aiBubbleColor: aiBubbleColor ?? this.aiBubbleColor,
      userTextColor: userTextColor ?? this.userTextColor,
      aiTextColor: aiTextColor ?? this.aiTextColor,
    );
  }
}
