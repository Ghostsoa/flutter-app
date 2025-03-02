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
                maxRounds: 20,
                streamResponse: true,
                chunkResponse: false,
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
        maxRounds: _config!.maxRounds,
        streamResponse: _config!.streamResponse,
        chunkResponse: _config!.chunkResponse,
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
                  child: Text(model.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = _config!.copyWith(model: value);
                  });
                }
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

            // Max Rounds
            _buildSlider(
              label: '最大对话轮数',
              description: '控制单个会话的最大对话轮数。超过此数量将自动结束会话。',
              value: _config!.maxRounds.toDouble(),
              onChanged: (value) {
                setState(() {
                  _config = _config!.copyWith(maxRounds: value.round());
                });
              },
              min: 5,
              max: 200,
              divisions: 195,
              valueFormatter: (value) => value.round().toString(),
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
                                // 如果开启流式响应，自动关闭分段返回
                                chunkResponse: false,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      '开启后将实时显示模型的响应内容，关闭后可以使用分段返回模式',
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

            // 分段返回开关
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
                          '分段返回',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: _config!.chunkResponse,
                          onChanged: _config!.streamResponse
                              ? null
                              : (value) {
                                  setState(() {
                                    _config = _config!.copyWith(
                                      chunkResponse: value,
                                    );
                                  });
                                },
                        ),
                      ],
                    ),
                    Text(
                      '仅在关闭流式响应时可用，开启后将每句话显示在单独的气泡中',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
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
