// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => ModelInfo(
      name: json['name'] as String,
      officialName: json['official_name'] as String,
      inputPrice: (json['input_price'] as num).toDouble(),
      outputPrice: (json['output_price'] as num).toDouble(),
    );

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
      'name': instance.name,
      'official_name': instance.officialName,
      'input_price': instance.inputPrice,
      'output_price': instance.outputPrice,
    };
