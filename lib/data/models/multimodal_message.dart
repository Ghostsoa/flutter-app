import 'package:json_annotation/json_annotation.dart';

part 'multimodal_message.g.dart';

@JsonSerializable()
class MessagePart {
  final String? text;
  @JsonKey(name: 'inline_data')
  final InlineData? inlineData;

  const MessagePart({
    this.text,
    this.inlineData,
  });

  factory MessagePart.fromJson(Map<String, dynamic> json) =>
      _$MessagePartFromJson(json);
  Map<String, dynamic> toJson() => _$MessagePartToJson(this);
}

@JsonSerializable()
class InlineData {
  @JsonKey(name: 'mime_type')
  final String mimeType;
  final String data;

  const InlineData({
    required this.mimeType,
    required this.data,
  });

  factory InlineData.fromJson(Map<String, dynamic> json) =>
      _$InlineDataFromJson(json);
  Map<String, dynamic> toJson() => _$InlineDataToJson(this);
}

@JsonSerializable()
class MultimodalMessage {
  final String role;
  final List<MessagePart> parts;
  final DateTime timestamp;
  final String id;

  const MultimodalMessage({
    required this.role,
    required this.parts,
    required this.timestamp,
    required this.id,
  });

  factory MultimodalMessage.fromJson(Map<String, dynamic> json) =>
      _$MultimodalMessageFromJson(json);
  Map<String, dynamic> toJson() => _$MultimodalMessageToJson(this);

  MultimodalMessage copyWith({
    String? role,
    List<MessagePart>? parts,
    DateTime? timestamp,
    String? id,
  }) {
    return MultimodalMessage(
      role: role ?? this.role,
      parts: parts ?? this.parts,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
    );
  }

  // 辅助方法：获取文本内容
  String? get text => parts
      .firstWhere(
        (part) => part.text != null,
        orElse: () => const MessagePart(),
      )
      .text;

  // 辅助方法：获取图片数据
  InlineData? get imageData => parts
      .firstWhere(
        (part) => part.inlineData?.mimeType.startsWith('image/') ?? false,
        orElse: () => const MessagePart(),
      )
      .inlineData;

  // 辅助方法：创建用户消息
  static MultimodalMessage createUserMessage({
    required String text,
    String? imageBase64,
    String imageMimeType = 'image/jpeg',
  }) {
    final parts = <MessagePart>[
      if (text.isNotEmpty) MessagePart(text: text),
      if (imageBase64 != null)
        MessagePart(
          inlineData: InlineData(
            mimeType: imageMimeType,
            data: imageBase64,
          ),
        ),
    ];

    return MultimodalMessage(
      role: 'user',
      parts: parts,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  // 辅助方法：创建AI响应消息
  static MultimodalMessage createModelMessage({
    required String text,
    String? generatedImageBase64,
  }) {
    final parts = <MessagePart>[
      MessagePart(text: text),
      if (generatedImageBase64 != null)
        MessagePart(
          inlineData: InlineData(
            mimeType: 'image/jpeg',
            data: generatedImageBase64,
          ),
        ),
    ];

    return MultimodalMessage(
      role: 'model',
      parts: parts,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

@JsonSerializable()
class TokenInfo {
  @JsonKey(name: 'prompt_tokens')
  final int promptTokens;
  @JsonKey(name: 'completion_tokens')
  final int completionTokens;
  @JsonKey(name: 'total_tokens')
  final int totalTokens;

  const TokenInfo({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) =>
      _$TokenInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TokenInfoToJson(this);
}

@JsonSerializable()
class MultimodalResponse {
  final String text;
  @JsonKey(name: 'image_data')
  final String? imageData;
  @JsonKey(name: 'token_info')
  final TokenInfo tokenInfo;

  const MultimodalResponse({
    required this.text,
    this.imageData,
    required this.tokenInfo,
  });

  factory MultimodalResponse.fromJson(Map<String, dynamic> json) =>
      _$MultimodalResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MultimodalResponseToJson(this);
}
