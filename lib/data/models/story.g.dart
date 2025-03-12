// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => Story(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      coverImagePath: json['coverImagePath'] as String?,
      backgroundImagePath: json['backgroundImagePath'] as String?,
      opening: json['opening'] as String,
      settings: json['settings'] as String,
      distillationRounds: (json['distillationRounds'] as num?)?.toInt() ?? 20,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'coverImagePath': instance.coverImagePath,
      'backgroundImagePath': instance.backgroundImagePath,
      'opening': instance.opening,
      'settings': instance.settings,
      'distillationRounds': instance.distillationRounds,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
