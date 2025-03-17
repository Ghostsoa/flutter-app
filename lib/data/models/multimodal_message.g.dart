// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multimodal_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessagePart _$MessagePartFromJson(Map<String, dynamic> json) => MessagePart(
      text: json['text'] as String?,
      inlineData: json['inline_data'] == null
          ? null
          : InlineData.fromJson(json['inline_data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessagePartToJson(MessagePart instance) =>
    <String, dynamic>{
      'text': instance.text,
      'inline_data': instance.inlineData,
    };

InlineData _$InlineDataFromJson(Map<String, dynamic> json) => InlineData(
      mimeType: json['mime_type'] as String,
      data: json['data'] as String,
    );

Map<String, dynamic> _$InlineDataToJson(InlineData instance) =>
    <String, dynamic>{
      'mime_type': instance.mimeType,
      'data': instance.data,
    };

MultimodalMessage _$MultimodalMessageFromJson(Map<String, dynamic> json) =>
    MultimodalMessage(
      role: json['role'] as String,
      parts: (json['parts'] as List<dynamic>)
          .map((e) => MessagePart.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$MultimodalMessageToJson(MultimodalMessage instance) =>
    <String, dynamic>{
      'role': instance.role,
      'parts': instance.parts,
      'timestamp': instance.timestamp.toIso8601String(),
      'id': instance.id,
    };

TokenInfo _$TokenInfoFromJson(Map<String, dynamic> json) => TokenInfo(
      promptTokens: (json['prompt_tokens'] as num).toInt(),
      completionTokens: (json['completion_tokens'] as num).toInt(),
      totalTokens: (json['total_tokens'] as num).toInt(),
    );

Map<String, dynamic> _$TokenInfoToJson(TokenInfo instance) => <String, dynamic>{
      'prompt_tokens': instance.promptTokens,
      'completion_tokens': instance.completionTokens,
      'total_tokens': instance.totalTokens,
    };

MultimodalResponse _$MultimodalResponseFromJson(Map<String, dynamic> json) =>
    MultimodalResponse(
      text: json['text'] as String,
      imageData: json['image_data'] as String?,
      tokenInfo: TokenInfo.fromJson(json['token_info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MultimodalResponseToJson(MultimodalResponse instance) =>
    <String, dynamic>{
      'text': instance.text,
      'image_data': instance.imageData,
      'token_info': instance.tokenInfo,
    };
