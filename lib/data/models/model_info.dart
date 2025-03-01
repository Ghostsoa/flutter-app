import 'package:json_annotation/json_annotation.dart';

part 'model_info.g.dart';

@JsonSerializable()
class ModelInfo {
  final String name;
  @JsonKey(name: 'official_name')
  final String officialName;
  @JsonKey(name: 'input_price')
  final double inputPrice;
  @JsonKey(name: 'output_price')
  final double outputPrice;

  ModelInfo({
    required this.name,
    required this.officialName,
    required this.inputPrice,
    required this.outputPrice,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ModelInfoToJson(this);
}
