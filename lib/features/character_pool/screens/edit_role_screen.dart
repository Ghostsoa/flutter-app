import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../../../data/models/group_chat_role.dart';

class EditRoleScreen extends StatefulWidget {
  final GroupChatRole? role;

  const EditRoleScreen({super.key, this.role});

  @override
  State<EditRoleScreen> createState() => _EditRoleScreenState();
}

class _EditRoleScreenState extends State<EditRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _avatarUrl;
  File? _selectedImage;
  String _selectedModel = 'gemini-2.0-flash';
  bool _useAdvancedSettings = false;
  double _temperature = 0.7;
  double _topP = 1.0;
  double _presencePenalty = 0.0;
  double _frequencyPenalty = 0.0;
  int _maxTokens = 2000;
  final _picker = ImagePicker();
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      _nameController.text = widget.role!.name;
      _descriptionController.text = widget.role!.description;
      _avatarUrl = widget.role!.avatarUrl;
      _selectedModel = widget.role!.model;
      _useAdvancedSettings = widget.role!.useAdvancedSettings;
      _temperature = widget.role!.temperature;
      _topP = widget.role!.topP;
      _presencePenalty = widget.role!.presencePenalty;
      _frequencyPenalty = widget.role!.frequencyPenalty;
      _maxTokens = widget.role!.maxTokens;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          _avatarUrl = null;
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
      final appDir = await getApplicationDocumentsDirectory();
      final groupsDir = Directory(path.join(appDir.path, 'groups'));
      if (!await groupsDir.exists()) {
        await groupsDir.create(recursive: true);
      }

      final extension = path.extension(file.path).toLowerCase();
      final isGif = extension == '.gif';
      final fileName = '${const Uuid().v4()}$extension';
      final savedPath = path.join(groupsDir.path, fileName);

      if (isGif) {
        await file.copy(savedPath);
      } else {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) throw '无法解码图片';

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

        final resized = img.copyResize(
          image,
          width: width.round(),
          height: height.round(),
          interpolation: img.Interpolation.linear,
        );

        final quality = extension == '.png' ? 9 : 85;
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

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: _selectedImage != null || _avatarUrl != null
                ? ClipOval(
                    child: Image(
                      image: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : _avatarUrl!.startsWith('/')
                              ? FileImage(File(_avatarUrl!))
                              : NetworkImage(_avatarUrl!) as ImageProvider,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击选择头像',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
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

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final role = GroupChatRole(
      id: widget.role?.id,
      name: _nameController.text,
      description: _descriptionController.text,
      avatarUrl: _selectedImage?.path ?? _avatarUrl,
      model: _selectedModel,
      useAdvancedSettings: _useAdvancedSettings,
      temperature: _temperature,
      topP: _topP,
      presencePenalty: _presencePenalty,
      frequencyPenalty: _frequencyPenalty,
      maxTokens: _maxTokens,
    );

    Navigator.of(context).pop(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == null ? '添加角色' : '编辑角色'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _handleSave,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
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
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: _buildImageSection()),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '角色名称',
                hintText: '输入角色名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入角色名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '角色描述',
                hintText: '描述这个角色的特点和设定',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入角色描述';
                }
                return null;
              },
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
                            label: 'Presence Penalty',
                            description: '控制模型避免重复主题的程度。较高的值会使模型更倾向于探索新的主题。',
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
                          _buildSlider(
                            label: 'Frequency Penalty',
                            description: '控制模型避免重复用词的程度。较高的值会使模型更倾向于使用新的词汇。',
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
                            label: 'Max Tokens',
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
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
