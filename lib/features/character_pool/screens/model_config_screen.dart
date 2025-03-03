import 'package:flutter/material.dart';
import '../../../data/models/model_config.dart';
import '../../../data/models/model_info.dart';
import '../../../data/repositories/model_config_repository.dart';
import '../../../core/network/api/model_api.dart';
import '../../../core/utils/logger.dart';

class ModelConfigScreen extends StatefulWidget {
  const ModelConfigScreen({super.key});

  @override
  State<ModelConfigScreen> createState() => _ModelConfigScreenState();
}

class _ModelConfigScreenState extends State<ModelConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ModelConfigRepository _repository;
  bool _isLoading = true;
  ModelConfig? _config;
  List<ModelInfo> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      setState(() => _isLoading = true);

      // 初始化仓库
      _repository = await ModelConfigRepository.create();
      final config = await _repository.getConfig();

      // 获取可用模型列表
      final modelApi = ModelApi.instance;
      await modelApi.initialize(); // 初始化 ModelApi
      final models = await modelApi.getModels();

      if (mounted) {
        setState(() {
          _availableModels = models;
          _config = config?.copyWith(
                // 如果当前选择的模型不在可用列表中，使用第一个可用模型
                model: models.any((m) => m.name == config.model)
                    ? config.model
                    : models.first.name,
              ) ??
              ModelConfig(
                model: models.first.name,
                temperature: 0.7,
                topP: 1.0,
                maxTokens: 2000,
                presencePenalty: 0.0,
                frequencyPenalty: 0.0,
                streamResponse: true,
              );
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.error('初始化模型配置失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败：$e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _initData,
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    try {
      final config = ModelConfig(
        model: _config!.model,
        temperature: _config!.temperature,
        topP: _config!.topP,
        maxTokens: _config!.maxTokens,
        presencePenalty: _config!.presencePenalty,
        frequencyPenalty: _config!.frequencyPenalty,
        streamResponse: _config!.streamResponse,
        enableDistillation: _config!.enableDistillation,
        distillationRounds: _config!.distillationRounds,
        distillationModel: _config!.distillationModel,
      );

      await _repository.saveConfig(config);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  Widget _buildSlider({
    required String label,
    required String description,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    int? divisions,
    String Function(double)? valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              valueFormatter?.call(value) ?? value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: divisions,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型配置'),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 模型选择
            DropdownButtonFormField<String>(
              value: _config!.model,
              decoration: const InputDecoration(
                labelText: '选择模型',
                border: OutlineInputBorder(),
              ),
              items: _availableModels.map((model) {
                return DropdownMenuItem(
                  value: model.name,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(model.name),
                      if (_config!.model != model.name) ...[
                        const SizedBox(height: 4),
                        Text(
                          '输入：${model.inputPrice / 10000}/1K tokens  输出：${model.outputPrice / 10000}/1K tokens',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = _config!.copyWith(model: value);
                  });
                }
              },
              selectedItemBuilder: (BuildContext context) {
                return _availableModels.map((model) {
                  return Text(model.name);
                }).toList();
              },
            ),
            const SizedBox(height: 24),

            // Temperature
            _buildSlider(
              label: 'Temperature',
              description: '控制输出的随机性。较高的值会使输出更加随机和创造性，较低的值会使输出更加集中和确定性。',
              value: _config!.temperature,
              onChanged: (value) {
                setState(() {
                  _config = _config!.copyWith(temperature: value);
                });
              },
              min: 0,
              max: 2,
              divisions: 20,
            ),

            // Top P
            _buildSlider(
              label: 'Top P',
              description: '控制输出的多样性。较高的值会保留更多的可能性，较低的值会使输出更加集中。',
              value: _config!.topP,
              onChanged: (value) {
                setState(() {
                  _config = _config!.copyWith(topP: value);
                });
              },
              min: 0,
              max: 1,
              divisions: 10,
            ),

            // Max Tokens
            _buildSlider(
              label: 'Max Tokens',
              description: '控制单次回复的最大长度。',
              value: _config!.maxTokens.toDouble(),
              onChanged: (value) {
                setState(() {
                  _config = _config!.copyWith(maxTokens: value.round());
                });
              },
              min: 100,
              max: 8196,
              divisions: 81,
              valueFormatter: (value) => value.round().toString(),
            ),

            // Presence Penalty
            _buildSlider(
              label: 'Presence Penalty',
              description: '控制模型重复使用相同主题的倾向。较高的值会使模型更倾向于讨论新主题。',
              value: _config!.presencePenalty,
              onChanged: (value) {
                setState(() {
                  _config = _config!.copyWith(presencePenalty: value);
                });
              },
              min: -2,
              max: 2,
              divisions: 40,
            ),

            // Frequency Penalty
            _buildSlider(
              label: 'Frequency Penalty',
              description: '控制模型重复使用相同词语的倾向。较高的值会使模型使用更多不同的词语。',
              value: _config!.frequencyPenalty,
              onChanged: (value) {
                setState(() {
                  _config = _config!.copyWith(frequencyPenalty: value);
                });
              },
              min: -2,
              max: 2,
              divisions: 40,
            ),

            const SizedBox(height: 24),

            // 流式响应开关
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '流式响应',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: _config!.streamResponse,
                          onChanged: (value) {
                            setState(() {
                              _config = _config!.copyWith(
                                streamResponse: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      '开启后将实时显示模型的响应内容',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 上下文蒸馏设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '上下文蒸馏(Beta测试)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: _config!.enableDistillation,
                          onChanged: (value) {
                            setState(() {
                              _config = _config!.copyWith(
                                enableDistillation: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      '开启后将在达到指定轮数时自动进行上下文蒸馏，以保持对话质量',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_config!.enableDistillation) ...[
                      const SizedBox(height: 16),
                      // 蒸馏轮数设置
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '蒸馏轮数',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '达到多少轮对话时进行一次蒸馏',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue:
                                  _config!.distillationRounds.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) {
                                final rounds = int.tryParse(value);
                                if (rounds != null && rounds > 0) {
                                  setState(() {
                                    _config = _config!.copyWith(
                                      distillationRounds: rounds,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 蒸馏模型选择
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '蒸馏模型',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '用于进行上下文蒸馏的模型，建议选择较强的模型以获得更好的效果',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _config!.distillationModel,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _availableModels.map((model) {
                              return DropdownMenuItem(
                                value: model.name,
                                child: Text(
                                  model.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _config = _config!.copyWith(
                                    distillationModel: value,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
