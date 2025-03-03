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
  final bool streamResponse;
  final bool enableDistillation;
  final int distillationRounds;
  final String distillationModel;

  ModelConfig({
    required this.model,
    this.temperature = 0.7,
    this.topP = 1.0,
    this.maxTokens = 8196,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.streamResponse = true,
    this.enableDistillation = false,
    this.distillationRounds = 20,
    this.distillationModel = 'gemini-1.5-pro',
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
    bool? streamResponse,
    bool? enableDistillation,
    int? distillationRounds,
    String? distillationModel,
  }) {
    return ModelConfig(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      streamResponse: streamResponse ?? this.streamResponse,
      enableDistillation: enableDistillation ?? this.enableDistillation,
      distillationRounds: distillationRounds ?? this.distillationRounds,
      distillationModel: distillationModel ?? this.distillationModel,
    );
  }
}
