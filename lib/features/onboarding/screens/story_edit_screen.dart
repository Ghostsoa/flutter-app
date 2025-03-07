import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../data/models/story.dart';
import '../../../data/local/shared_prefs/story_storage.dart';

class CategoryData {
  final String id;
  final String title;
  final Color color;

  const CategoryData({
    required this.id,
    required this.title,
    required this.color,
  });
}

class StoryEditScreen extends StatefulWidget {
  final bool isEditing;
  final Story? story;

  const StoryEditScreen({
    super.key,
    this.isEditing = false,
    this.story,
  });

  @override
  State<StoryEditScreen> createState() => _StoryEditScreenState();
}

class _StoryEditScreenState extends State<StoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final StoryStorage _storage;
  bool _isLoading = false;

  String? _selectedCategoryId = 'xiuxian';
  File? _coverImageFile;
  File? _backgroundImageFile;
  String? _coverImagePath;
  String? _backgroundImagePath;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingController = TextEditingController();
  final _settingsController = TextEditingController();
  final _distillationRoundsController = TextEditingController();

  // 分类数据
  final List<CategoryData> _categories = [
    const CategoryData(
      id: 'xiuxian',
      title: '修仙',
      color: Color(0xFFE056FD),
    ),
    const CategoryData(
      id: 'thriller',
      title: '惊悚',
      color: Color(0xFFFF7675),
    ),
    const CategoryData(
      id: 'ancient',
      title: '古风',
      color: Color(0xFF74B9FF),
    ),
    const CategoryData(
      id: 'urban',
      title: '都市',
      color: Color(0xFF00B894),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initStorage();
    if (widget.story != null) {
      _titleController.text = widget.story!.title;
      _descriptionController.text = widget.story!.description;
      _openingController.text = widget.story!.opening;
      _settingsController.text = widget.story!.settings;
      _selectedCategoryId = widget.story!.categoryId;
      _coverImagePath = widget.story!.coverImagePath;
      _backgroundImagePath = widget.story!.backgroundImagePath;
      _distillationRoundsController.text =
          widget.story!.distillationRounds.toString();
      if (widget.story!.coverImagePath != null) {
        _coverImageFile = File(widget.story!.coverImagePath!);
      }
      if (widget.story!.backgroundImagePath != null) {
        _backgroundImageFile = File(widget.story!.backgroundImagePath!);
      }
    } else {
      _distillationRoundsController.text = '50'; // 默认值
    }
  }

  Future<void> _initStorage() async {
    _storage = await StoryStorage.init();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final String? coverPath = _coverImageFile != null
            ? await _saveImageFile(_coverImageFile!)
            : _coverImagePath;
        final String? backgroundPath = _backgroundImageFile != null
            ? await _saveImageFile(_backgroundImageFile!)
            : _backgroundImagePath;

        final story = Story(
          id: widget.story?.id ?? const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategoryId!,
          coverImagePath: coverPath,
          backgroundImagePath: backgroundPath,
          opening: _openingController.text,
          settings: _settingsController.text,
          distillationRounds: int.parse(_distillationRoundsController.text),
          createdAt: widget.story?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _storage.saveStory(story);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<String> _saveImageFile(File file) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final storiesDir = Directory(path.join(appDir.path, 'stories'));
      if (!await storiesDir.exists()) {
        await storiesDir.create(recursive: true);
      }

      // 获取原始文件扩展名
      final extension = path.extension(file.path).toLowerCase();

      // 生成唯一文件名，保持原始扩展名
      final fileName = '${const Uuid().v4()}$extension';
      final savedFile = File(path.join(storiesDir.path, fileName));

      // 直接复制文件，保持原始格式
      await file.copy(savedFile.path);

      return savedFile.path;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      rethrow;
    }
  }

  Future<void> _pickImage(bool isCover) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          if (isCover) {
            _coverImageFile = File(image.path);
            _coverImagePath = null;
          } else {
            _backgroundImageFile = File(image.path);
            _backgroundImagePath = null;
          }
        });
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  Widget _buildImageUploader({
    required String title,
    required String? imagePath,
    required File? imageFile,
    required VoidCallback onTap,
    double height = 120,
  }) {
    Widget imageWidget;
    if (imageFile != null) {
      final extension = path.extension(imageFile.path).toLowerCase();
      if (extension == '.gif') {
        imageWidget = Image.file(
          imageFile,
          fit: BoxFit.cover,
          cacheWidth: null,
          cacheHeight: null,
          gaplessPlayback: true,
          isAntiAlias: true,
          filterQuality: FilterQuality.high,
        );
      } else {
        imageWidget = Image.file(
          imageFile,
          fit: BoxFit.cover,
        );
      }
    } else if (imagePath != null) {
      final extension = path.extension(imagePath).toLowerCase();
      if (extension == '.gif') {
        imageWidget = Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          cacheWidth: null,
          cacheHeight: null,
          gaplessPlayback: true,
          isAntiAlias: true,
          filterQuality: FilterQuality.high,
        );
      } else {
        imageWidget = Image.file(
          File(imagePath),
          fit: BoxFit.cover,
        );
      }
    } else {
      imageWidget = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                '从相册选择',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageWidget,
                if (imageFile != null || imagePath != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          if (title == '封面图') {
                            _coverImageFile = null;
                            _coverImagePath = null;
                          } else {
                            _backgroundImageFile = null;
                            _backgroundImagePath = null;
                          }
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _openingController.dispose();
    _settingsController.dispose();
    _distillationRoundsController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '此项不能为空';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final category = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '故事分类',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: category.id,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E2530),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: category.color,
                        size: 24,
                      ),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: category.color,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              category.title,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _handleSave,
              child: Text(
                '保存',
                style: TextStyle(
                  color: Colors.blue[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // 主背景
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1F25),
                  const Color(0xFF141619),
                  const Color(0xFF0D0E10),
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    Colors.white.withOpacity(0.12), // 顶部光源
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1A1F25).withOpacity(0.3),
                      const Color(0xFF1A1F25).withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // 内容
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    widget.isEditing ? '编辑故事' : '创建故事',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageUploader(
                          title: '封面图',
                          imagePath: _coverImagePath,
                          imageFile: _coverImageFile,
                          onTap: () => _pickImage(true),
                          height: 120,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImageUploader(
                          title: '背景图',
                          imagePath: _backgroundImagePath,
                          imageFile: _backgroundImageFile,
                          onTap: () => _pickImage(false),
                          height: 120,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: '故事名称',
                    controller: _titleController,
                    hintText: '请输入故事名称',
                  ),
                  const SizedBox(height: 24),
                  _buildCategorySelector(),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: '故事介绍',
                    controller: _descriptionController,
                    hintText: '请输入故事简介',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: '故事开场白',
                    controller: _openingController,
                    hintText: '请输入故事开场白',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: '故事设定',
                    controller: _settingsController,
                    hintText: '请输入故事世界观、人物设定等内容',
                    maxLines: 6,
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '上下文蒸馏轮数',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'BETA',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '针对故事对话轮数进行蒸馏，大幅度降低token，轻度影响记忆',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _distillationRoundsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '10-100',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入轮数';
                            }
                            final rounds = int.tryParse(value);
                            if (rounds == null) {
                              return '请输入数字';
                            }
                            if (rounds < 10 || rounds > 100) {
                              return '范围:10-100';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
