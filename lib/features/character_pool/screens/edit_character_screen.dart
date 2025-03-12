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
      final character = CharacterCodec.decode(encoded);

      if (character == null) {
        throw '无效的角色数据格式';
      }

      if (!mounted) return;

      // 如果有图片数据，需要保存图片
      String? coverImageUrl;
      if (character.coverImageUrl != null) {
        final imageFile = File(character.coverImageUrl!);
        if (await imageFile.exists()) {
          coverImageUrl = await _processAndSaveImage(imageFile);
        }
      }

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
        _coverImageUrl = coverImageUrl;
        _selectedImage = coverImageUrl != null ? File(coverImageUrl) : null;
        _useMarkdown = character.useMarkdown;
        _hasStatus = character.hasStatus;
        _statusList = List.from(character.statusList);
        _backgroundOpacity = character.backgroundOpacity;
        _userBubbleColor = character.userBubbleColor;
        _aiBubbleColor = character.aiBubbleColor;
        _userTextColor = character.userTextColor;
        _aiTextColor = character.aiTextColor;
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
