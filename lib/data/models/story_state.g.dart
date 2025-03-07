// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryState _$StoryStateFromJson(Map<String, dynamic> json) => StoryState(
      storyId: json['storyId'] as String,
      statusUpdates: json['statusUpdates'] as Map<String, dynamic>,
      nextActions: (json['nextActions'] as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StoryStateToJson(StoryState instance) =>
    <String, dynamic>{
      'storyId': instance.storyId,
      'statusUpdates': instance.statusUpdates,
      'nextActions': instance.nextActions,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
