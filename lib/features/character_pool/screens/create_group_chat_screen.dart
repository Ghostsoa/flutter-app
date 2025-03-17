import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../../../data/models/group_chat_role.dart';
import './edit_role_screen.dart';
import '../../../data/repositories/group_chat_repository.dart';
import '../../../data/models/group_chat.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class CreateGroupChatScreen extends StatefulWidget {
  final GroupChat? group;
  final String? importFilePath;

  const CreateGroupChatScreen({
    super.key,
    this.group,
    this.importFilePath,
  });

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _greetingController = TextEditingController();
  final _roleNameController = TextEditingController();
  final _roleDescriptionController = TextEditingController();
  final _settingController = TextEditingController();
  String? _coverImageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _useMarkdown = false;
  bool _streamResponse = true;
  bool _enableDistillation = false;
  int _distillationRounds = 20;
  final List<GroupChatRole> _roles = [];
  GroupChatRole? _selectedRole;
  final _picker = ImagePicker();
  bool _showDecisionProcess = false;
  late final String _groupId;

  @override
  void initState() {
    super.initState();
    _groupId = widget.group?.id ?? const Uuid().v4();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _settingController.text = widget.group!.setting ?? '';
      _greetingController.text = widget.group!.greeting ?? '';
      _useMarkdown = widget.group!.useMarkdown;
      _showDecisionProcess = widget.group!.showDecisionProcess;
      _streamResponse = widget.group!.streamResponse;
      _enableDistillation = widget.group!.enableDistillation;
      _distillationRounds = widget.group!.distillationRounds;

      // 先添加角色，但使用占位图片
      for (final role in widget.group!.roles) {
        _roles.add(role.copyWith(avatarUrl: null));
      }
      _selectedRole = _roles.isNotEmpty ? _roles.first : null;
      _updateRoleControllers();

      // 异步加载图片
      _initializeImages();
    }
  }

  Future<void> _initializeImages() async {
    try {
      setState(() => _isLoading = true);

      // 并行加载所有图片
      await Future.wait([
        // 加载背景图片
        if (widget.group!.backgroundImageData != null)
          _loadBackgroundImage(widget.group!.backgroundImageData!),

        // 加载所有角色头像
        ..._roles.where((r) => r.avatarUrl != null).map((role) async {
          final bytes = base64Decode(role.avatarUrl!);
          final tempDir = await getTemporaryDirectory();
          final extension = _detectImageFormat(bytes);
          final tempFile =
              File('${tempDir.path}/${const Uuid().v4()}.$extension');
          await tempFile.writeAsBytes(bytes);

          if (!mounted) return;

          final index = _roles.indexWhere((r) => r.id == role.id);
          if (index != -1) {
            setState(() {
              _roles[index] = _roles[index].copyWith(avatarUrl: tempFile.path);
              if (_selectedRole?.id == role.id) {
                _selectedRole = _roles[index];
              }
            });
          }
        }),
      ]);
    } catch (e) {
      debugPrint('加载图片失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBackgroundImage(String base64Data) async {
    try {
      final bytes = base64Decode(base64Data);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${const Uuid().v4()}.jpg');
      await tempFile.writeAsBytes(bytes);
      setState(() {
        _selectedImage = tempFile;
      });
    } catch (e) {
      debugPrint('加载背景图片失败: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _greetingController.dispose();
    _roleNameController.dispose();
    _roleDescriptionController.dispose();
    _settingController.dispose();
    super.dispose();
  }

  void _updateRoleControllers() {
    if (_selectedRole != null) {
      _roleNameController.text = _selectedRole!.name;
      _roleDescriptionController.text = _selectedRole!.description;
    } else {
      _roleNameController.text = '';
      _roleDescriptionController.text = '';
    }
  }

  void _handleRoleSelect(GroupChatRole role) {
    setState(() {
      _selectedRole = role;
      _updateRoleControllers();
    });
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
      final appDir = await getApplicationDocumentsDirectory();
      final groupsDir = Directory(path.join(appDir.path, 'groups'));
      if (!await groupsDir.exists()) {
        await groupsDir.create(recursive: true);
      }

      final extension = path.extension(file.path).toLowerCase();
      final fileName = '${const Uuid().v4()}$extension';
      final savedPath = path.join(groupsDir.path, fileName);

      // 如果是GIF文件，直接复制不做处理
      if (extension == '.gif') {
        await file.copy(savedPath);
        return savedPath;
      }

      // 处理其他图片格式
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

      // 根据文件类型选择合适的压缩参数
      if (extension == '.png') {
        final encoded = img.encodePng(resized, level: 6); // 降低PNG压缩级别以保持质量
        await File(savedPath).writeAsBytes(encoded);
      } else {
        final encoded = img.encodeJpg(resized, quality: 92); // 提高JPG质量
        await File(savedPath).writeAsBytes(encoded);
      }

      return savedPath;
    } catch (e) {
      debugPrint('处理图片失败: $e');
      rethrow;
    }
  }

  void _showAddRoleDialog() {
    Navigator.of(context)
        .push<GroupChatRole>(
      MaterialPageRoute(
        builder: (context) => const EditRoleScreen(),
      ),
    )
        .then((role) {
      if (role != null) {
        setState(() {
          _roles.add(role);
          _selectedRole = role;
          _updateRoleControllers();
        });
      }
    });
  }

  Widget _buildRoleAvatar(GroupChatRole role) {
    final isSelected = _selectedRole?.id == role.id;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _handleRoleSelect(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 100,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.2),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: role.avatarUrl == null
                    ? Icon(
                        Icons.person_outline,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : Stack(
                        children: [
                          Image.file(
                            File(role.avatarUrl!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            gaplessPlayback:
                                role.avatarUrl!.toLowerCase().endsWith('.gif'),
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person_outline,
                                size: 32,
                                color: theme.colorScheme.onSurfaceVariant,
                              );
                            },
                          ),
                          if (_isLoading)
                            Container(
                              color: Colors.black26,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRoleAvatar() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _showAddRoleDialog,
      child: SizedBox(
        width: 80,
        height: 100,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添加角色',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '群聊背景',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: _selectedImage != null || _coverImageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image(
                                image: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                        as ImageProvider
                                    : _coverImageUrl!.startsWith('/')
                                        ? FileImage(File(_coverImageUrl!))
                                        : NetworkImage(_coverImageUrl!)
                                            as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // 添加一个半透明的遮罩，让图标和文字更清晰
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '点击更换背景',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '添加群聊背景',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _saveAvatarData(String base64Data, String dirPath) async {
    try {
      // 处理可能包含的 base64 前缀
      final base64String =
          base64Data.contains(',') ? base64Data.split(',')[1] : base64Data;
      final bytes = base64Decode(base64String);

      // 检测图片格式
      final extension = _detectImageFormat(bytes);
      final fileName = '${const Uuid().v4()}.$extension';
      final avatarPath = path.join(dirPath, fileName);

      // 将数据写入文件
      await File(avatarPath).writeAsBytes(bytes);
      return avatarPath;
    } catch (e) {
      debugPrint('保存角色头像失败: $e');
      return null;
    }
  }

  Future<void> _handleImport() async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      // 读取文件内容
      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      // 获取存储目录
      final appDir = await getApplicationDocumentsDirectory();
      final groupsDir = Directory(path.join(appDir.path, 'groups'));
      if (!await groupsDir.exists()) {
        await groupsDir.create(recursive: true);
      }

      if (!mounted) return;

      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入群聊'),
          content: Text('是否要导入群聊【${jsonData['name']}】？'),
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
        _nameController.text = jsonData['name'];
        _settingController.text = jsonData['setting'] ?? '';
        _greetingController.text = jsonData['greeting'] ?? '';
        _showDecisionProcess = jsonData['showDecisionProcess'] ?? false;
        _streamResponse = jsonData['streamResponse'] ?? true;
        _enableDistillation = jsonData['enableDistillation'] ?? false;
        _distillationRounds = jsonData['distillationRounds'] ?? 20;

        // 清空现有角色列表
        _roles.clear();
      });

      // 添加角色
      for (final roleData in jsonData['roles']) {
        String? avatarUrl;

        // 如果有avatarData，优先使用它
        if (roleData['avatarData'] != null) {
          final bytes = base64Decode(roleData['avatarData']);
          final extension = _detectImageFormat(bytes);
          final fileName = '${const Uuid().v4()}.$extension';
          final avatarPath = path.join(groupsDir.path, fileName);
          await File(avatarPath).writeAsBytes(bytes);
          avatarUrl = avatarPath;
        } else if (roleData['avatarUrl'] != null) {
          // 如果有 avatarUrl 且是 base64 数据
          final base64Data = roleData['avatarUrl'] as String;
          if (base64Data.contains('base64,') || base64Data.contains('/9j/')) {
            final bytes = base64Decode(base64Data.contains(',')
                ? base64Data.split(',')[1]
                : base64Data);
            final extension = _detectImageFormat(bytes);
            final fileName = '${const Uuid().v4()}.$extension';
            final avatarPath = path.join(groupsDir.path, fileName);
            await File(avatarPath).writeAsBytes(bytes);
            avatarUrl = avatarPath;
          }
        }

        // 处理 modelConfig
        final modelConfig =
            roleData['modelConfig'] as Map<String, dynamic>? ?? {};
        final role = GroupChatRole(
          id: const Uuid().v4(),
          name: roleData['name'],
          description: roleData['description'],
          avatarUrl: avatarUrl,
          model: modelConfig['model'] ?? 'gemini-2.0-flash',
          useAdvancedSettings: modelConfig['useAdvancedSettings'] ?? false,
          temperature: modelConfig['temperature']?.toDouble() ?? 0.7,
          topP: modelConfig['topP']?.toDouble() ?? 1.0,
          presencePenalty: modelConfig['presencePenalty']?.toDouble() ?? 0.0,
          frequencyPenalty: modelConfig['frequencyPenalty']?.toDouble() ?? 0.0,
          maxTokens: modelConfig['maxTokens'] ?? 2000,
        );

        setState(() {
          _roles.add(role);
        });
      }

      setState(() {
        _selectedRole = _roles.isNotEmpty ? _roles.first : null;
      });

      // 处理背景图片
      if (jsonData['backgroundImageData'] != null) {
        final savedPath = await _saveAvatarData(
            jsonData['backgroundImageData'], groupsDir.path);
        if (savedPath != null && mounted) {
          setState(() {
            _selectedImage = File(savedPath);
          });
        }
      }

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群聊导入成功')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    }
  }

  // 检测图片格式
  String _detectImageFormat(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 && // G
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46) {
      // F
      return 'gif';
    } else if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      // JPEG
      return 'jpg';
    } else if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      // PNG
      return 'png';
    }
    return 'jpg'; // 默认返回jpg
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group == null ? '创建群聊' : '编辑群聊'),
        actions: [
          if (widget.group == null) // 只在创建新群聊时显示导入按钮
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: '导入群聊',
              onPressed: _handleImport,
            ),
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 背景图片部分
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  // 群聊基本设定
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.groups_outlined,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '群聊设定',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '群聊名称',
                            hintText: '简单描述这个群聊的设定（如：三国演义）',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.edit_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入群聊名称';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _settingController,
                          minLines: 3,
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: '群聊设定',
                            hintText: '描述群聊的背景、规则和设定',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.settings_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _greetingController,
                          minLines: 3,
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: '开场白',
                            hintText: '群聊开始时的开场白',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.chat_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('启用 Markdown'),
                                subtitle: const Text('允许在对话中使用 Markdown 格式'),
                                value: _useMarkdown,
                                onChanged: (value) =>
                                    setState(() => _useMarkdown = value),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: Row(
                                  children: [
                                    const Text('智能决策控制'),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Beta',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: const Text('开启后可以控制发言角色以及发言顺序'),
                                value: _showDecisionProcess,
                                onChanged: (value) => setState(
                                    () => _showDecisionProcess = value),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: const Text('流式响应'),
                                subtitle: const Text('开启后可以实时看到角色的回复'),
                                value: _streamResponse,
                                onChanged: (value) =>
                                    setState(() => _streamResponse = value),
                              ),
                              const Divider(height: 1),
                              Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('启用蒸馏'),
                                    subtitle: const Text('通过多轮对话优化输出质量'),
                                    value: _enableDistillation,
                                    onChanged: (value) {
                                      setState(() {
                                        _enableDistillation = value;
                                      });
                                    },
                                  ),
                                  if (_enableDistillation)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 8, 16, 16),
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
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              controller: TextEditingController(
                                                text: _distillationRounds
                                                    .toString(),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
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
                                                filled: true,
                                                fillColor: theme.colorScheme
                                                    .surfaceContainerHighest
                                                    .withOpacity(0.3),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                              onChanged: (value) {
                                                final rounds =
                                                    int.tryParse(value);
                                                if (rounds != null &&
                                                    rounds > 0 &&
                                                    rounds <= 100) {
                                                  setState(() {
                                                    _distillationRounds =
                                                        rounds;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 角色列表标题
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '角色列表',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            '${_roles.length}/4',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 角色头像列表
                  SizedBox(
                    height: 100,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._roles.map((role) => _buildRoleAvatar(role)),
                        if (_roles.length < 4) _buildAddRoleAvatar(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 分隔线和标题
                  if (_selectedRole != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '角色设置',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                              _selectedRole!.name.isEmpty
                                  ? '未命名'
                                  : _selectedRole!.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                _roles.remove(_selectedRole);
                                _selectedRole =
                                    _roles.isEmpty ? null : _roles.first;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_selectedRole == null)
            SliverFillRemaining(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '还没有角色',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _showAddRoleDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('添加角色'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 添加头像设置部分
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            final savedPath =
                                await _processAndSaveImage(File(image.path));
                            setState(() {
                              _selectedRole!.avatarUrl = savedPath;
                            });
                          }
                        },
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
                          child: _selectedRole!.avatarUrl != null
                              ? ClipOval(
                                  child: _selectedRole!.avatarUrl!
                                          .toLowerCase()
                                          .endsWith('.gif')
                                      ? Image.file(
                                          File(_selectedRole!.avatarUrl!),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person_outline,
                                              size: 48,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(_selectedRole!.avatarUrl!),
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
                                      '点击更换头像',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _roleNameController,
                    decoration: const InputDecoration(
                      labelText: '角色名称',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole!.name = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _roleDescriptionController,
                    minLines: 3,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: '角色描述',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole!.description = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole!.model,
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
                          _selectedRole!.model = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('启用高级设置'),
                          subtitle: const Text('调整模型参数以获得更好的效果'),
                          value: _selectedRole!.useAdvancedSettings,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole!.useAdvancedSettings = value;
                            });
                          },
                        ),
                        if (_selectedRole!.useAdvancedSettings) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildSlider(
                                  label: 'Temperature',
                                  value: _selectedRole!.temperature,
                                  min: 0,
                                  max: 2,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole!.temperature = value;
                                    });
                                  },
                                ),
                                _buildSlider(
                                  label: 'Top P',
                                  value: _selectedRole!.topP,
                                  min: 0,
                                  max: 1,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole!.topP = value;
                                    });
                                  },
                                ),
                                _buildSlider(
                                  label: 'Presence Penalty',
                                  value: _selectedRole!.presencePenalty,
                                  min: -2,
                                  max: 2,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole!.presencePenalty = value;
                                    });
                                  },
                                ),
                                _buildSlider(
                                  label: 'Frequency Penalty',
                                  value: _selectedRole!.frequencyPenalty,
                                  min: -2,
                                  max: 2,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole!.frequencyPenalty = value;
                                    });
                                  },
                                ),
                                _buildSlider(
                                  label: 'Max Tokens',
                                  value: _selectedRole!.maxTokens.toDouble(),
                                  min: 100,
                                  max: 4000,
                                  divisions: 39,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole!.maxTokens = value.round();
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
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要添加2个角色')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repository = await GroupChatRepository.create();

      String? backgroundImageData;
      if (_selectedImage != null) {
        backgroundImageData = await repository.processImage(_selectedImage!);
      }

      final processedRoles = await Future.wait(
        _roles.map((role) async {
          if (role.avatarUrl != null) {
            final avatarFile = File(role.avatarUrl!);
            if (await avatarFile.exists()) {
              final avatarData = await repository.processImage(
                avatarFile,
                maxSize: 400,
              );
              return role.copyWith(avatarUrl: avatarData);
            }
          }
          return role;
        }),
      );

      final groupChat = GroupChat(
        id: _groupId,
        name: _nameController.text,
        setting:
            _settingController.text.isEmpty ? null : _settingController.text,
        greeting:
            _greetingController.text.isEmpty ? null : _greetingController.text,
        backgroundImageData: backgroundImageData,
        useMarkdown: _useMarkdown,
        showDecisionProcess: _showDecisionProcess,
        streamResponse: _streamResponse,
        enableDistillation: _enableDistillation,
        distillationRounds: _distillationRounds,
        roles: processedRoles,
      );

      await repository.saveGroupChat(groupChat);

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
}
