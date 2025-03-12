import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import './group_chat_role.dart';

part 'group_chat.g.dart';

@JsonSerializable()
class GroupChat {
  final String id;
  final String name;
  final String? setting;
  final String? greeting;
  final String? backgroundImageData; // Base64编码的图片数据
  final bool useMarkdown;
  final bool showDecisionProcess;
  final bool streamResponse;
  final bool enableDistillation;
  final int distillationRounds;
  final String? distillationModel;
  final List<GroupChatRole> roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupChat({
    String? id,
    required this.name,
    this.setting,
    this.greeting,
    this.backgroundImageData,
    this.useMarkdown = false,
    this.showDecisionProcess = false,
    this.streamResponse = true,
    this.enableDistillation = false,
    this.distillationRounds = 20,
    this.distillationModel,
    required this.roles,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory GroupChat.fromJson(Map<String, dynamic> json) =>
      _$GroupChatFromJson(json);

  Map<String, dynamic> toJson() => _$GroupChatToJson(this);

  GroupChat copyWith({
    String? id,
    String? name,
    String? setting,
    String? greeting,
    String? backgroundImageData,
    bool? useMarkdown,
    bool? showDecisionProcess,
    bool? streamResponse,
    bool? enableDistillation,
    int? distillationRounds,
    String? distillationModel,
    List<GroupChatRole>? roles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupChat(
      id: id ?? this.id,
      name: name ?? this.name,
      setting: setting ?? this.setting,
      greeting: greeting ?? this.greeting,
      backgroundImageData: backgroundImageData ?? this.backgroundImageData,
      useMarkdown: useMarkdown ?? this.useMarkdown,
      showDecisionProcess: showDecisionProcess ?? this.showDecisionProcess,
      streamResponse: streamResponse ?? this.streamResponse,
      enableDistillation: enableDistillation ?? this.enableDistillation,
      distillationRounds: distillationRounds ?? this.distillationRounds,
      distillationModel: distillationModel ?? this.distillationModel,
      roles: roles ?? List.from(this.roles),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
