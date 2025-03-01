import 'package:json_annotation/json_annotation.dart';

part 'api_log.g.dart';

@JsonSerializable()
class ApiLog {
  final String id;
  final String endpoint;
  final int tokens;
  final double cost;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  ApiLog({
    required this.id,
    required this.endpoint,
    required this.tokens,
    required this.cost,
    required this.status,
    required this.createdAt,
  });

  factory ApiLog.fromJson(Map<String, dynamic> json) => _$ApiLogFromJson(json);
  Map<String, dynamic> toJson() => _$ApiLogToJson(this);
}
