import 'package:json_annotation/json_annotation.dart';
import './model_config.dart';

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
  final bool useAlgorithmFormat; // 是否使用算法格式化输出
  final bool hasStatus; // 是否启用状态
  final List<CharacterStatus> statusList; // 状态列表

  // 聊天界面样式设置
  final double backgroundOpacity; // 背景透明度
  final String userBubbleColor; // 用户气泡颜色
  final String aiBubbleColor; // AI气泡颜色
  final String userTextColor; // 用户文本颜色
  final String aiTextColor; // AI文本颜色

  // 模型配置
  final String model; // 使用的模型
  final bool useAdvancedSettings; // 是否使用高级设置
  final double temperature; // 温度
  final double topP; // Top P
  final double presencePenalty; // 主题惩罚
  final double frequencyPenalty; // 重复惩罚
  final int maxTokens; // 最大tokens
  final bool streamResponse; // 是否使用流式响应
  final bool enableDistillation; // 是否启用蒸馏
  final int distillationRounds; // 蒸馏轮数
  final String distillationModel; // 蒸馏模型

  Character({
    required this.id,
    required this.name,
    required this.description,
    this.coverImageUrl,
    this.userSetting,
    this.greeting,
    this.useMarkdown = false,
    this.useAlgorithmFormat = true,
    this.hasStatus = false,
    this.statusList = const [],
    this.backgroundOpacity = 0.5,
    this.userBubbleColor = '#2196F3', // 默认蓝色
    this.aiBubbleColor = '#1A1A1A', // 默认深灰色
    this.userTextColor = '#FFFFFF', // 默认白色
    this.aiTextColor = '#FFFFFF', // 默认白色
    this.model = 'gemini-2.0-flash',
    this.useAdvancedSettings = false,
    this.temperature = 0.7,
    this.topP = 1.0,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.maxTokens = 2000,
    this.streamResponse = true,
    this.enableDistillation = false,
    this.distillationRounds = 20,
    this.distillationModel = 'gemini-distill',
  }) : assert(!(useMarkdown && useAlgorithmFormat), '不能同时启用 Markdown 和算法格式化');

  factory Character.fromJson(Map<String, dynamic> json) {
    // 处理旧版本数据，如果没有 useAlgorithmFormat 字段，根据 useMarkdown 来设置
    final useMarkdown = json['useMarkdown'] as bool? ?? false;
    final useAlgorithmFormat =
        json['useAlgorithmFormat'] as bool? ?? !useMarkdown;

    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      userSetting: json['userSetting'] as String?,
      greeting: json['greeting'] as String?,
      useMarkdown: useMarkdown,
      useAlgorithmFormat: useAlgorithmFormat,
      hasStatus: json['hasStatus'] as bool? ?? false,
      statusList: (json['statusList'] as List<dynamic>?)
              ?.map((e) => CharacterStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.5,
      userBubbleColor: json['userBubbleColor'] as String? ?? '#2196F3',
      aiBubbleColor: json['aiBubbleColor'] as String? ?? '#1A1A1A',
      userTextColor: json['userTextColor'] as String? ?? '#FFFFFF',
      aiTextColor: json['aiTextColor'] as String? ?? '#FFFFFF',
      model: json['model'] as String? ?? 'gemini-2.0-flash',
      useAdvancedSettings: json['useAdvancedSettings'] as bool? ?? false,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      maxTokens: json['maxTokens'] as int? ?? 2000,
      streamResponse: json['streamResponse'] as bool? ?? true,
      enableDistillation: json['enableDistillation'] as bool? ?? false,
      distillationRounds: json['distillationRounds'] as int? ?? 20,
      distillationModel:
          json['distillationModel'] as String? ?? 'gemini-distill',
    );
  }

  Map<String, dynamic> toJson() => _$CharacterToJson(this);

  Character copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImageUrl,
    String? userSetting,
    String? greeting,
    bool? useMarkdown,
    bool? useAlgorithmFormat,
    bool? hasStatus,
    List<CharacterStatus>? statusList,
    double? backgroundOpacity,
    String? userBubbleColor,
    String? aiBubbleColor,
    String? userTextColor,
    String? aiTextColor,
    String? model,
    bool? useAdvancedSettings,
    double? temperature,
    double? topP,
    double? presencePenalty,
    double? frequencyPenalty,
    int? maxTokens,
    bool? streamResponse,
    bool? enableDistillation,
    int? distillationRounds,
    String? distillationModel,
  }) {
    final newUseMarkdown = useMarkdown ?? this.useMarkdown;
    final newUseAlgorithmFormat = useAlgorithmFormat ?? this.useAlgorithmFormat;
    assert(
        !(newUseMarkdown && newUseAlgorithmFormat), '不能同时启用 Markdown 和算法格式化');

    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      userSetting: userSetting ?? this.userSetting,
      greeting: greeting ?? this.greeting,
      useMarkdown: newUseMarkdown,
      useAlgorithmFormat: newUseAlgorithmFormat,
      hasStatus: hasStatus ?? this.hasStatus,
      statusList: statusList ?? this.statusList,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      aiBubbleColor: aiBubbleColor ?? this.aiBubbleColor,
      userTextColor: userTextColor ?? this.userTextColor,
      aiTextColor: aiTextColor ?? this.aiTextColor,
      model: model ?? this.model,
      useAdvancedSettings: useAdvancedSettings ?? this.useAdvancedSettings,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      maxTokens: maxTokens ?? this.maxTokens,
      streamResponse: streamResponse ?? this.streamResponse,
      enableDistillation: enableDistillation ?? this.enableDistillation,
      distillationRounds: distillationRounds ?? this.distillationRounds,
      distillationModel: distillationModel ?? this.distillationModel,
    );
  }

  ModelConfig toModelConfig() {
    if (!useAdvancedSettings) {
      return ModelConfig(
        model: model,
        temperature: 0.7,
        topP: 1.0,
        maxTokens: 2000,
        presencePenalty: 0.0,
        frequencyPenalty: 0.0,
        streamResponse: true,
        enableDistillation: false,
        distillationRounds: 20,
        distillationModel: 'gemini-distill',
      );
    }

    return ModelConfig(
      model: model,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      streamResponse: streamResponse,
      enableDistillation: enableDistillation,
      distillationRounds: distillationRounds,
      distillationModel: distillationModel,
    );
  }
}
