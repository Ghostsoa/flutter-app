import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import '../../../data/models/character.dart';
import '../../../data/repositories/character_repository.dart';

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
  String? _coverImageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _useMarkdown = false;
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

  @override
  void initState() {
    super.initState();
    _initRepository();
    _characterId = widget.character?.id ?? const Uuid().v4();
    if (widget.character != null) {
      _nameController.text = widget.character!.name;
      _descriptionController.text = widget.character!.description;
      _userSettingController.text = widget.character!.userSetting ?? '';
      _coverImageUrl = widget.character!.coverImageUrl;
      _useMarkdown = widget.character!.useMarkdown;
      _hasStatus = widget.character!.hasStatus;
      _statusList = List.from(widget.character!.statusList);
      _backgroundOpacity = widget.character!.backgroundOpacity;
      _userBubbleColor = widget.character!.userBubbleColor;
      _aiBubbleColor = widget.character!.aiBubbleColor;
      _userTextColor = widget.character!.userTextColor;
      _aiTextColor = widget.character!.aiTextColor;
    }
  }

  Future<void> _initRepository() async {
    _repository = await CharacterRepository.create();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _userSettingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
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
        useMarkdown: _useMarkdown,
        hasStatus: _hasStatus,
        statusList: _statusList,
        backgroundOpacity: _backgroundOpacity,
        userBubbleColor: _userBubbleColor,
        aiBubbleColor: _aiBubbleColor,
        userTextColor: _userTextColor,
        aiTextColor: _aiTextColor,
      );

      final savedCharacter = await _repository.saveCharacter(character);
      if (mounted) {
        Navigator.of(context).pop(savedCharacter);
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

  void _addStatus() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String type = 'text';

        return AlertDialog(
          title: const Text('添加状态'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '状态名称',
                  hintText: '例如：生命值、心情等',
                ),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: '状态类型',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'text',
                    child: Text('文本'),
                  ),
                  DropdownMenuItem(
                    value: 'number',
                    child: Text('数值'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    type = value;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    _statusList.add(CharacterStatus(
                      name: name,
                      type: type,
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '状态列表',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _addStatus,
              icon: const Icon(Icons.add),
              label: const Text('添加状态'),
            ),
          ],
        ),
        if (_statusList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '暂无状态',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _statusList.length,
            itemBuilder: (context, index) {
              final status = _statusList[index];
              return Card(
                child: ListTile(
                  title: Text(status.name),
                  subtitle: Text(status.type == 'text' ? '文本类型' : '数值类型'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _statusList.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildChatStyleSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '聊天界面设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 背景透明度设置
        Row(
          children: [
            const Text('背景透明度'),
            Expanded(
              child: Slider(
                value: _backgroundOpacity,
                onChanged: (value) {
                  setState(() => _backgroundOpacity = value);
                },
                min: 0,
                max: 1,
                divisions: 10,
                label: '${(_backgroundOpacity * 100).round()}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 用户气泡颜色
        ListTile(
          title: const Text('用户气泡颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hexToColor(_userBubbleColor),
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => _showColorPicker(
            '选择用户气泡颜色',
            _userBubbleColor,
            (color) => setState(() => _userBubbleColor = color),
          ),
        ),

        // AI气泡颜色
        ListTile(
          title: const Text('AI气泡颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hexToColor(_aiBubbleColor),
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => _showColorPicker(
            '选择AI气泡颜色',
            _aiBubbleColor,
            (color) => setState(() => _aiBubbleColor = color),
          ),
        ),

        // 用户文本颜色
        ListTile(
          title: const Text('用户文本颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hexToColor(_userTextColor),
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => _showColorPicker(
            '选择用户文本颜色',
            _userTextColor,
            (color) => setState(() => _userTextColor = color),
          ),
        ),

        // AI文本颜色
        ListTile(
          title: const Text('AI文本颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hexToColor(_aiTextColor),
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => _showColorPicker(
            '选择AI文本颜色',
            _aiTextColor,
            (color) => setState(() => _aiTextColor = color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character != null ? '编辑角色' : '创建角色'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 封面选择
            AspectRatio(
              aspectRatio: 0.75,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickImage,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_selectedImage != null)
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        )
                      else if (_coverImageUrl != null)
                        _coverImageUrl!.startsWith('/')
                            ? Image.file(
                                File(_coverImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _coverImageUrl!,
                                fit: BoxFit.cover,
                              )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 64,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '选择封面',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 名字输入
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '角色名字',
                hintText: '给你的角色起个名字',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入角色名字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 描述输入
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '角色描述',
                hintText: '描述一下这个角色的性格、特点等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 5,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入角色描述';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 用户设定输入
            TextFormField(
              controller: _userSettingController,
              decoration: const InputDecoration(
                labelText: '用户设定',
                hintText: '添加额外的用户设定（可选）',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
            ),
            const SizedBox(height: 16),

            // Markdown格式化开关
            SwitchListTile(
              title: const Text('使用Markdown格式化'),
              subtitle: Text(
                _hasStatus
                    ? '启用状态功能时无法使用Markdown格式化'
                    : '开启后将使用Markdown格式渲染描述文本',
                style: TextStyle(
                  color: _hasStatus ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              value: _useMarkdown,
              onChanged: _hasStatus
                  ? null
                  : (value) {
                      setState(() {
                        _useMarkdown = value;
                      });
                    },
            ),
            const SizedBox(height: 16),

            // 状态功能开关
            SwitchListTile(
              title: const Text('启用状态功能'),
              subtitle: Text(
                _useMarkdown ? '使用Markdown格式化时无法启用状态功能' : '开启后可以为角色添加自定义状态',
                style: TextStyle(
                  color: _useMarkdown ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              value: _hasStatus,
              onChanged: _useMarkdown
                  ? null
                  : (value) {
                      setState(() {
                        _hasStatus = value;
                        if (!value) {
                          _statusList.clear();
                        }
                      });
                    },
            ),

            if (_hasStatus) ...[
              const SizedBox(height: 16),
              _buildStatusList(),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // 添加聊天界面设置
            _buildChatStyleSettings(),
          ],
        ),
      ),
    );
  }
}
