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
  final _scrollController = ScrollController();
  late final ModelConfigRepository _repository;
  bool _isLoading = true;
  ModelConfig? _config;
  List<ModelInfo> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      setState(() => _isLoading = true);

      _repository = await ModelConfigRepository.create();
      final config = await _repository.getConfig();

      final modelApi = ModelApi.instance;
      await modelApi.initialize();
      final models = await modelApi.getModels();

      if (mounted) {
        setState(() {
          _availableModels = models;
          // 过滤掉特殊用途的模型
          final displayModels = models
              .where((model) => ![
                    'gemini-distill',
                    'gemini-decisync',
                    'gemini-story'
                  ].contains(model.name))
              .toList();

          _config = config?.copyWith(
                model: displayModels.any((m) => m.name == config.model)
                    ? config.model
                    : displayModels.first.name,
                distillationModel: 'gemini-distill', // 固定使用 gemini-distill
              ) ??
              ModelConfig(
                model: displayModels.first.name,
                temperature: 0.7,
                topP: 1.0,
                maxTokens: 2000,
                presencePenalty: 0.0,
                frequencyPenalty: 0.0,
                streamResponse: true,
                enableDistillation: false,
                distillationRounds: 20,
                distillationModel: 'gemini-distill', // 固定使用 gemini-distill
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

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueFormatter?.call(value) ?? value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: divisions,
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelector() {
    // 过滤掉特殊用途的模型
    final displayModels = _availableModels
        .where((model) => !['gemini-distill', 'gemini-decisync', 'gemini-story']
            .contains(model.name))
        .toList();

    final selectedModel = displayModels.firstWhere(
      (model) => model.name == _config!.model,
      orElse: () => displayModels.first,
    );

    return _buildSection(
      title: '模型选择',
      description: '选择要使用的AI模型，不同模型有不同的特点和价格。',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _config!.model,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: displayModels.map((model) {
              return DropdownMenuItem(
                value: model.name,
                child: Text(
                  model.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
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
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '当前模型价格',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceInfo(
                  label: '输入价格',
                  price: selectedModel.inputPrice / 100,
                ),
                const SizedBox(height: 8),
                _buildPriceInfo(
                  label: '输出价格',
                  price: selectedModel.outputPrice / 100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo({required String label, required double price}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '$price 小懿币/1w tokens',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildParametersSection() {
    return _buildSection(
      title: '参数设置',
      description: '调整模型的输出参数，以获得不同的效果。',
      child: Column(
        children: [
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
          const SizedBox(height: 24),
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
            divisions: 20,
          ),
          const SizedBox(height: 24),
          _buildSlider(
            label: '最大Tokens',
            description: '控制单次输出的最大长度。',
            value: _config!.maxTokens.toDouble(),
            onChanged: (value) {
              setState(() {
                _config = _config!.copyWith(maxTokens: value.round());
              });
            },
            min: 100,
            max: 4000,
            divisions: 39,
            valueFormatter: (value) => value.round().toString(),
          ),
          const SizedBox(height: 24),
          _buildSlider(
            label: '重复惩罚',
            description: '控制模型避免重复内容的程度。较高的值会使模型更倾向于生成新的内容。',
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
          _buildSlider(
            label: '主题惩罚',
            description: '控制模型保持主题的程度。较高的值会使模型更倾向于探索新的主题。',
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
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return _buildSection(
      title: '高级设置',
      description: '一些高级功能的开关设置。',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('流式响应'),
            subtitle: const Text('开启后可以实时看到模型的输出'),
            value: _config!.streamResponse,
            onChanged: (value) {
              setState(() {
                _config = _config!.copyWith(streamResponse: value);
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: Row(
              children: [
                const Text('启用蒸馏'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Beta',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text('通过多轮对话优化输出质量'),
            value: _config!.enableDistillation,
            onChanged: (value) {
              setState(() {
                _config = _config!.copyWith(enableDistillation: value);
              });
            },
          ),
          if (_config!.enableDistillation) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '蒸馏轮数',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '进行多少轮优化，轮数越多效果越好，但耗时也越长。',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _config!.distillationRounds.toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            isDense: true,
                            hintText: '20',
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            final rounds = int.tryParse(value);
                            if (rounds != null && rounds > 0 && rounds <= 100) {
                              setState(() {
                                _config = _config!.copyWith(
                                  distillationRounds: rounds,
                                  distillationModel:
                                      'gemini-distill', // 固定使用 gemini-distill
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
          TextButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _buildModelSelector(),
            _buildParametersSection(),
            _buildAdvancedSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
