import 'package:json_annotation/json_annotation.dart';

part 'hall_item.g.dart';

@JsonSerializable()
class HallItem {
  final int id;
  final String name;
  final String description;
  @JsonKey(name: 'author_id')
  final int authorId;
  @JsonKey(name: 'author_name')
  final String authorName;
  final String type;
  @JsonKey(name: 'role_count')
  final int roleCount;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  @JsonKey(name: 'config_url')
  final String configUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  HallItem({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.roleCount,
    this.coverImage,
    required this.configUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HallItem.fromJson(Map<String, dynamic> json) =>
      _$HallItemFromJson(json);
  Map<String, dynamic> toJson() => _$HallItemToJson(this);
}

@JsonSerializable()
class HallResponse {
  final int total;
  final List<HallItem> list;
  final int page;
  final int pages;

  HallResponse({
    required this.total,
    required this.list,
    required this.page,
    required this.pages,
  });

  factory HallResponse.fromJson(Map<String, dynamic> json) =>
      _$HallResponseFromJson(json);
  Map<String, dynamic> toJson() => _$HallResponseToJson(this);
}
