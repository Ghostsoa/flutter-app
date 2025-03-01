// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiLog _$ApiLogFromJson(Map<String, dynamic> json) => ApiLog(
      id: json['id'] as String,
      endpoint: json['endpoint'] as String,
      tokens: (json['tokens'] as num).toInt(),
      cost: (json['cost'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ApiLogToJson(ApiLog instance) => <String, dynamic>{
      'id': instance.id,
      'endpoint': instance.endpoint,
      'tokens': instance.tokens,
      'cost': instance.cost,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };
