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
  final _greetingController = TextEditingController();
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

  final _scrollController = ScrollController();

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
      _hasStatus = widget.character!.hasStatus;
      _statusList = List.from(widget.character!.statusList);
      _backgroundOpacity = widget.character!.backgroundOpacity;
      _userBubbleColor = widget.character!.userBubbleColor;
      _aiBubbleColor = widget.character!.aiBubbleColor;
      _userTextColor = widget.character!.userTextColor;
      _aiTextColor = widget.character!.aiTextColor;
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
        greeting:
            _greetingController.text.isEmpty ? null : _greetingController.text,
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
            FilledButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    _statusList.add(CharacterStatus(
                      name: name,
                      type: type,
                      value: type == 'number' ? '0' : '',
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

  Widget _buildImageSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
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

  Widget _buildStatusSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '状态设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _hasStatus,
                  onChanged: (value) => setState(() => _hasStatus = value),
                ),
              ],
            ),
            if (_hasStatus) ...[
              const SizedBox(height: 16),
              ..._statusList.map((status) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(status.name),
                      subtitle: Text(status.type == 'text' ? '文本' : '数值'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _statusList.remove(status)),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: _addStatus,
                  icon: const Icon(Icons.add),
                  label: const Text('添加状态'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character == null ? '新建角色' : '编辑角色'),
        actions: [
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
              label: '名称',
              controller: _nameController,
              hint: '角色的名字',
              required: true,
            ),
            _buildTextField(
              label: '描述',
              controller: _descriptionController,
              hint: '角色的个性、背景故事等',
              maxLines: 3,
              required: true,
            ),
            _buildTextField(
              label: '用户设定',
              controller: _userSettingController,
              hint: '可选：设定用户在对话中扮演的角色',
              maxLines: 2,
            ),
            _buildTextField(
              label: '开场白',
              controller: _greetingController,
              hint: '可选：角色的开场白',
              maxLines: 2,
            ),
            SwitchListTile(
              title: const Text('启用Markdown'),
              subtitle: const Text('允许在对话中使用Markdown格式'),
              value: _useMarkdown,
              onChanged: (value) => setState(() => _useMarkdown = value),
            ),
            _buildColorSection(),
            _buildStatusSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
