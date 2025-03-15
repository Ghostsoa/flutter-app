// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hall_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HallItem _$HallItemFromJson(Map<String, dynamic> json) => HallItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      authorId: (json['author_id'] as num).toInt(),
      authorName: json['author_name'] as String,
      type: json['type'] as String,
      roleCount: (json['role_count'] as num).toInt(),
      coverImage: json['cover_image'] as String?,
      configUrl: json['config_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$HallItemToJson(HallItem instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'author_id': instance.authorId,
      'author_name': instance.authorName,
      'type': instance.type,
      'role_count': instance.roleCount,
      'cover_image': instance.coverImage,
      'config_url': instance.configUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

HallResponse _$HallResponseFromJson(Map<String, dynamic> json) => HallResponse(
      total: (json['total'] as num).toInt(),
      list: (json['list'] as List<dynamic>)
          .map((e) => HallItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$HallResponseToJson(HallResponse instance) =>
    <String, dynamic>{
      'total': instance.total,
      'list': instance.list,
      'page': instance.page,
      'pages': instance.pages,
    };
