import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import '../../../data/models/character.dart';
import '../../../data/repositories/character_repository.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/character_codec.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class EditCharacterScreen extends StatefulWidget {
  final Character? character;

  const EditCharacterScreen({
    super.key,
    this.character,
  });

  @override
  State<EditCharacterScreen> createState() => _EditCharacterScreenState();
}

class _EditCharacterScreenState extends State<EditCharacterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _userSettingController = TextEditingController();
  final _greetingController = TextEditingController();
  String? _coverImageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _useMarkdown = false;
  bool _useAlgorithmFormat = true;
  bool _hasStatus = false;
  List<CharacterStatus> _statusList = [];
  final _picker = ImagePicker();
  late final CharacterRepository _repository;
  late final String _characterId;
  double _backgroundOpacity = 0.5;
  String _userBubbleColor = '#2196F3';
  String _aiBubbleColor = '#1A1A1A';
  String _userTextColor = '#FFFFFF';
  String _aiTextColor = '#FFFFFF';

  final _scrollController = ScrollController();

  // 模型配置
  String _selectedModel = 'gemini-2.0-flash';
  bool _useAdvancedSettings = false;
  double _temperature = 0.7;
  double _topP = 1.0;
  double _presencePenalty = 0.0;
  double _frequencyPenalty = 0.0;
  int _maxTokens = 2000;
  bool _streamResponse = true;
  bool _enableDistillation = false;
  int _distillationRounds = 20;
  String _distillationModel = 'gemini-distill';

  @override
  void initState() {
    super.initState();
    _initRepository();
    _characterId = widget.character?.id ?? const Uuid().v4();
    if (widget.character != null) {
      _nameController.text = widget.character!.name;
      _descriptionController.text = widget.character!.description;
      _userSettingController.text = widget.character!.userSetting ?? '';
      _greetingController.text = widget.character!.greeting ?? '';
      _coverImageUrl = widget.character!.coverImageUrl;
      _useMarkdown = widget.character!.useMarkdown;
      _useAlgorithmFormat = widget.character!.useAlgorithmFormat;
      _hasStatus = widget.character!.hasStatus;
      _statusList = List.from(widget.character!.statusList);
      _backgroundOpacity = widget.character!.backgroundOpacity;
      _userBubbleColor = widget.character!.userBubbleColor;
      _aiBubbleColor = widget.character!.aiBubbleColor;
      _userTextColor = widget.character!.userTextColor;
      _aiTextColor = widget.character!.aiTextColor;
      _selectedModel = widget.character!.model;
      _useAdvancedSettings = widget.character!.useAdvancedSettings;
      _temperature = widget.character!.temperature;
      _topP = widget.character!.topP;
      _presencePenalty = widget.character!.presencePenalty;
      _frequencyPenalty = widget.character!.frequencyPenalty;
      _maxTokens = widget.character!.maxTokens;
      _streamResponse = widget.character!.streamResponse;
      _enableDistillation = widget.character!.enableDistillation;
      _distillationRounds = widget.character!.distillationRounds;
      _distillationModel = widget.character!.distillationModel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _userSettingController.dispose();
    _greetingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initRepository() async {
    _repository = await CharacterRepository.create();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        final savedPath = await _processAndSaveImage(File(image.path));
        setState(() {
          _selectedImage = File(savedPath);
          _coverImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败：$e')),
        );
      }
    }
  }

  Future<String> _processAndSaveImage(File file) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final charactersDir = Directory(path.join(appDir.path, 'characters'));
      if (!await charactersDir.exists()) {
        await charactersDir.create(recursive: true);
      }

      // 获取原始文件扩展名
      final extension = path.extension(file.path).toLowerCase();
      final isGif = extension == '.gif';

      // 生成唯一文件名
      final fileName = '${const Uuid().v4()}$extension';
      final savedPath = path.join(charactersDir.path, fileName);

      if (isGif) {
        // GIF文件直接复制
        await file.copy(savedPath);
      } else {
        // 读取图片
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);

        if (image == null) throw '无法解码图片';

        // 计算新的尺寸（保持宽高比）
        const maxSize = 800.0;
        double width = image.width.toDouble();
        double height = image.height.toDouble();

        if (width > maxSize || height > maxSize) {
          if (width > height) {
            height = height * (maxSize / width);
            width = maxSize;
          } else {
            width = width * (maxSize / height);
            height = maxSize;
          }
        }

        // 调整图片大小
        final resized = img.copyResize(
          image,
          width: width.round(),
          height: height.round(),
          interpolation: img.Interpolation.linear,
        );

        // 保存图片
        final quality = extension == '.png' ? 9 : 85; // PNG使用压缩级别，JPG使用质量
        if (extension == '.png') {
          final encoded = img.encodePng(resized, level: quality);
          await File(savedPath).writeAsBytes(encoded);
        } else {
          final encoded = img.encodeJpg(resized, quality: quality);
          await File(savedPath).writeAsBytes(encoded);
        }
      }

      return savedPath;
    } catch (e) {
      debugPrint('处理图片失败: $e');
      rethrow;
    }
  }

  Future<void> _showColorPicker(String title, String initialColor,
      void Function(String) onColorChanged) async {
    Color pickerColor = _hexToColor(initialColor);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                },
                pickerAreaHeightPercent: 0.8,
                enableAlpha: true,
                displayThumbColor: true,
                portraitOnly: true,
              ),
              const SizedBox(height: 16),
              Text(
                '当前颜色: #${pickerColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              onColorChanged(
                  '#${pickerColor.value.toRadixString(16).padLeft(8, '0')}');
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 8) {
      return Color(int.parse(hexColor, radix: 16));
    } else if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.black;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final character = Character(
        id: _characterId,
        name: _nameController.text,
        description: _descriptionController.text,
        coverImageUrl: _selectedImage?.path ?? _coverImageUrl,
        userSetting: _userSettingController.text.isEmpty
            ? null
            : _userSettingController.text,
        greeting:
            _greetingController.text.isEmpty ? null : _greetingController.text,
        useMarkdown: _useMarkdown,
        useAlgorithmFormat: _useAlgorithmFormat,
        hasStatus: _hasStatus,
        statusList: _statusList,
        backgroundOpacity: _backgroundOpacity,
        userBubbleColor: _userBubbleColor,
        aiBubbleColor: _aiBubbleColor,
        userTextColor: _userTextColor,
        aiTextColor: _aiTextColor,
        model: _selectedModel,
        useAdvancedSettings: _useAdvancedSettings,
        temperature: _temperature,
        topP: _topP,
        presencePenalty: _presencePenalty,
        frequencyPenalty: _frequencyPenalty,
        maxTokens: _maxTokens,
        streamResponse: _streamResponse,
        enableDistillation: _enableDistillation,
        distillationRounds: _distillationRounds,
        distillationModel: _distillationModel,
      );

      await _repository.saveCharacter(character);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      if (!await file.exists()) throw '文件不存在';

      // 读取并解码文件内容
      final encoded = await file.readAsString();
      final character = await CharacterCodec.decode(encoded);

      if (character == null) {
        throw '无效的角色数据格式';
      }

      if (!mounted) return;

      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入角色'),
          content: Text('是否要导入角色【${character.name}】的设置？\n导入后您仍可以修改各项参数。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('导入'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // 填充表单数据
      setState(() {
        _nameController.text = character.name;
        _descriptionController.text = character.description;
        _userSettingController.text = character.userSetting ?? '';
        _greetingController.text = character.greeting ?? '';
        _coverImageUrl = character.coverImageUrl;
        _selectedImage = character.coverImageUrl != null
            ? File(character.coverImageUrl!)
            : null;
        _useMarkdown = character.useMarkdown;
        _useAlgorithmFormat = character.useAlgorithmFormat;
        _hasStatus = character.hasStatus;
        _statusList = List.from(character.statusList);
        _backgroundOpacity = character.backgroundOpacity;
        _userBubbleColor = character.userBubbleColor;
        _aiBubbleColor = character.aiBubbleColor;
        _userTextColor = character.userTextColor;
        _aiTextColor = character.aiTextColor;
        _selectedModel = character.model;
        _useAdvancedSettings = character.useAdvancedSettings;
        _temperature = character.temperature;
        _topP = character.topP;
        _presencePenalty = character.presencePenalty;
        _frequencyPenalty = character.frequencyPenalty;
        _maxTokens = character.maxTokens;
        _streamResponse = character.streamResponse;
        _enableDistillation = character.enableDistillation;
        _distillationRounds = character.distillationRounds;
        _distillationModel = character.distillationModel;
      });

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入角色【${character.name}】的设置'),
          action: SnackBarAction(
            label: '确定',
            onPressed: () {},
          ),
        ),
      );

      // 滚动到顶部
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    }
  }

  Widget _buildImageSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _selectedImage != null || _coverImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image(
                    image: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : _coverImageUrl!.startsWith('/')
                            ? FileImage(File(_coverImageUrl!))
                            : NetworkImage(_coverImageUrl!) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _pickImage,
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        minLines: maxLines,
        maxLines: null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '$label不能为空';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildColorSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '聊天气泡设置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('用户气泡颜色'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showColorPicker(
                          '选择用户气泡颜色',
                          _userBubbleColor,
                          (color) => setState(() => _userBubbleColor = color),
                        ),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(_userBubbleColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI气泡颜色'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showColorPicker(
                          '选择AI气泡颜色',
                          _aiBubbleColor,
                          (color) => setState(() => _aiBubbleColor = color),
                        ),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(_aiBubbleColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('用户文字颜色'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showColorPicker(
                          '选择用户文字颜色',
                          _userTextColor,
                          (color) => setState(() => _userTextColor = color),
                        ),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(_userTextColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI文字颜色'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showColorPicker(
                          '选择AI文字颜色',
                          _aiTextColor,
                          (color) => setState(() => _aiTextColor = color),
                        ),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(_aiTextColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('背景透明度'),
                Slider(
                  value: _backgroundOpacity,
                  onChanged: (value) =>
                      setState(() => _backgroundOpacity = value),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(_backgroundOpacity * 100).round()}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.1),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模型设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedModel,
          decoration: const InputDecoration(
            labelText: '选择模型',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.auto_awesome_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: 'gemini-2.0-flash',
              child: Text('Gemini 2.0 Flash'),
            ),
            DropdownMenuItem(
              value: 'gemini-2.0-flash-exp',
              child: Text('Gemini 2.0 Flash EXP'),
            ),
            DropdownMenuItem(
              value: 'gemini-2-lite',
              child: Text('Gemini 2 Lite'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedModel = value;
              });
            }
          },
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('启用高级设置'),
                subtitle: const Text('调整模型参数以获得更好的效果'),
                value: _useAdvancedSettings,
                onChanged: (value) {
                  setState(() {
                    _useAdvancedSettings = value;
                    if (!value) {
                      // 关闭高级设置时，重置相关参数
                      _streamResponse = true;
                      _enableDistillation = false;
                    }
                  });
                },
              ),
              if (_useAdvancedSettings) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSlider(
                        label: 'Temperature',
                        description:
                            '控制输出的随机性。较高的值会使输出更加随机和创造性，较低的值会使输出更加集中和确定性。',
                        value: _temperature,
                        min: 0,
                        max: 2,
                        divisions: 20,
                        onChanged: (value) {
                          setState(() {
                            _temperature = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSlider(
                        label: 'Top P',
                        description: '控制输出的多样性。较高的值会保留更多的可能性，较低的值会使输出更加集中。',
                        value: _topP,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _topP = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSlider(
                        label: '最大Tokens',
                        description: '控制单次输出的最大长度。',
                        value: _maxTokens.toDouble(),
                        min: 100,
                        max: 4000,
                        divisions: 39,
                        onChanged: (value) {
                          setState(() {
                            _maxTokens = value.round();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSlider(
                        label: '重复惩罚',
                        description: '控制模型避免重复内容的程度。较高的值会使模型更倾向于生成新的内容。',
                        value: _frequencyPenalty,
                        min: -2,
                        max: 2,
                        divisions: 40,
                        onChanged: (value) {
                          setState(() {
                            _frequencyPenalty = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSlider(
                        label: '主题惩罚',
                        description: '控制模型保持主题的程度。较高的值会使模型更倾向于探索新的主题。',
                        value: _presencePenalty,
                        min: -2,
                        max: 2,
                        divisions: 40,
                        onChanged: (value) {
                          setState(() {
                            _presencePenalty = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('流式响应'),
                        subtitle: const Text('开启后可以实时看到模型的输出'),
                        value: _streamResponse,
                        onChanged: (value) {
                          setState(() {
                            _streamResponse = value;
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Beta',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text('通过多轮对话优化输出质量'),
                        value: _enableDistillation,
                        onChanged: (value) {
                          setState(() {
                            _enableDistillation = value;
                          });
                        },
                      ),
                      if (_enableDistillation) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      initialValue:
                                          _distillationRounds.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                                        if (rounds != null &&
                                            rounds > 0 &&
                                            rounds <= 100) {
                                          setState(() {
                                            _distillationRounds = rounds;
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
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SwitchListTile(
            title: Row(
              children: [
                const Text('使用算法格式化'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('算法格式化说明'),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '自动处理以下格式的换行：',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '1. 普通文本[动作]\n',
                                      style: TextStyle(height: 2),
                                    ),
                                    TextSpan(text: '   → '),
                                    TextSpan(
                                      text: '普通文本\n[动作]',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '2. [动作]普通文本\n',
                                      style: TextStyle(height: 2),
                                    ),
                                    TextSpan(text: '   → '),
                                    TextSpan(
                                      text: '[动作]\n普通文本',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '3. 普通文本（补充）\n',
                                      style: TextStyle(height: 2),
                                    ),
                                    TextSpan(text: '   → '),
                                    TextSpan(
                                      text: '普通文本\n（补充）',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '支持的符号：',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text('• 方括号：[ ] 【 】'),
                              const Text('• 圆括号：( ) （ ）'),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          '提示',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '此功能会自动在括号前后添加换行，使对话内容和动作/补充说明更加清晰。同时所有文本会自动添加彩色高亮以提升可读性。',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('了解了'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: '查看格式化说明',
                ),
              ],
            ),
            subtitle: const Text('请详细阅读说明'),
            value: _useAlgorithmFormat,
            onChanged: (value) {
              setState(() {
                _useAlgorithmFormat = value;
                if (value) {
                  _useMarkdown = false;
                }
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('使用 Markdown'),
            subtitle: const Text('使用 Markdown 格式渲染文本'),
            value: _useMarkdown,
            onChanged: (value) {
              setState(() {
                _useMarkdown = value;
                if (value) {
                  _useAlgorithmFormat = false;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character == null ? '新建角色' : '编辑角色'),
        actions: [
          if (widget.character == null)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: '导入角色',
              onPressed: () => _handleImport(context),
            ),
          TextButton.icon(
            onPressed: _isLoading ? null : _handleSave,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined),
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
            _buildImageSection(),
            const SizedBox(height: 16),
            _buildTextField(
              label: '角色名称',
              controller: _nameController,
              required: true,
            ),
            _buildTextField(
              label: '角色描述',
              controller: _descriptionController,
              maxLines: 3,
              required: true,
            ),
            _buildTextField(
              label: '用户设定（可选）',
              controller: _userSettingController,
              maxLines: 3,
              hint: '添加额外的角色设定...',
            ),
            _buildTextField(
              label: '开场白（可选）',
              controller: _greetingController,
              maxLines: 3,
              hint: '设置对话开始时的开场白...',
            ),
            _buildFormatSection(),
            _buildColorSection(),
            const SizedBox(height: 16),
            _buildModelSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
