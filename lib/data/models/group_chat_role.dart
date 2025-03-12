import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import './character.dart';
import './model_config.dart';

part 'group_chat_role.g.dart';

@JsonSerializable()
class GroupChatRole {
  final String id;
  String name;
  String? avatarUrl;
  String description;
  String model;
  bool useAdvancedSettings;
  double temperature;
  double topP;
  double presencePenalty;
  double frequencyPenalty;
  int maxTokens;

  GroupChatRole({
    String? id,
    this.name = '',
    this.avatarUrl,
    this.description = '',
    this.model = 'gemini-2.0-flash',
    this.useAdvancedSettings = false,
    this.temperature = 0.7,
    this.topP = 1.0,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.maxTokens = 2000,
  }) : id = id ?? const Uuid().v4();

  factory GroupChatRole.fromJson(Map<String, dynamic> json) =>
      _$GroupChatRoleFromJson(json);

  Map<String, dynamic> toJson() => _$GroupChatRoleToJson(this);

  GroupChatRole copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? description,
    String? model,
    bool? useAdvancedSettings,
    double? temperature,
    double? topP,
    double? presencePenalty,
    double? frequencyPenalty,
    int? maxTokens,
  }) {
    return GroupChatRole(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      model: model ?? this.model,
      useAdvancedSettings: useAdvancedSettings ?? this.useAdvancedSettings,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  Character toCharacter() {
    return Character(
      id: id,
      name: name,
      description: description,
      coverImageUrl: avatarUrl,
      useMarkdown: false,
      hasStatus: false,
      statusList: const [],
      backgroundOpacity: 0.5,
      userBubbleColor: '#2196F3',
      aiBubbleColor: '#1A1A1A',
      userTextColor: '#FFFFFF',
      aiTextColor: '#FFFFFF',
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
        distillationRounds: 20,
      );
    }

    return ModelConfig(
      model: model,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      streamResponse: true,
      distillationRounds: 20,
    );
  }
}
