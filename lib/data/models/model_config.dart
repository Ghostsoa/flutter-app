import 'package:json_annotation/json_annotation.dart';

part 'model_config.g.dart';

@JsonSerializable()
class ModelConfig {
  final String model;
  final double temperature;
  final double topP;
  final int maxTokens;
  final double presencePenalty;
  final double frequencyPenalty;
  final int maxRounds;
  final bool streamResponse;
  final bool chunkResponse;

  ModelConfig({
    required this.model,
    this.temperature = 0.7,
    this.topP = 1.0,
    this.maxTokens = 8196,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.maxRounds = 200,
    this.streamResponse = true,
    this.chunkResponse = false,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ModelConfigToJson(this);

  ModelConfig copyWith({
    String? model,
    double? temperature,
    double? topP,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    int? maxRounds,
    bool? streamResponse,
    bool? chunkResponse,
  }) {
    final isStream = streamResponse ?? this.streamResponse;
    return ModelConfig(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      maxRounds: maxRounds ?? this.maxRounds,
      streamResponse: isStream,
      chunkResponse: isStream ? false : (chunkResponse ?? this.chunkResponse),
    );
  }

  bool get canControlChunkResponse => !streamResponse;
}
