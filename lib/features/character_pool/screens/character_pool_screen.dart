import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/character_card.dart';
import './edit_character_screen.dart';
import '../../../data/models/character.dart';
import '../../../data/repositories/character_repository.dart';
import '../../../data/repositories/model_config_repository.dart';
import '../../../data/repositories/chat_archive_repository.dart';
import '../../../core/utils/character_codec.dart';
import './model_config_screen.dart';
import '../../chat/screens/chat_screen.dart';
import 'dart:convert';

class CharacterPoolScreen extends StatefulWidget {
  const CharacterPoolScreen({super.key});

  @override
  State<CharacterPoolScreen> createState() => _CharacterPoolScreenState();
}

class _CharacterPoolScreenState extends State<CharacterPoolScreen> {
  late final CharacterRepository _repository;
  late final ModelConfigRepository _modelConfigRepository;
  List<Character> _characters = [];
  bool _isLoading = true;
  bool _hasModelConfig = false;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repository = await CharacterRepository.create();
    _modelConfigRepository = await ModelConfigRepository.create();
    await _checkModelConfig();
    await _loadCharacters();
  }

  Future<void> _checkModelConfig() async {
    final config = await _modelConfigRepository.getConfig();
    if (mounted) {
      setState(() {
        _hasModelConfig = config != null;
      });
    }
  }

  Future<void> _navigateToModelConfig() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModelConfigScreen(),
      ),
    );
    if (result == true && mounted) {
      await _checkModelConfig();
    }
  }

  Future<void> _loadCharacters() async {
    try {
      final characters = await _repository.getAllCharacters();
      if (mounted) {
        setState(() {
          _characters = characters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载角色失败：$e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEdit(BuildContext context, Character? character) async {
    final result = await Navigator.of(context).push<Character>(
      MaterialPageRoute(
        builder: (context) => EditCharacterScreen(
          character: character,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadCharacters();
    }
  }

  Future<void> _handleDelete(BuildContext context, String characterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除角色'),
        content: const Text('确定要删除这个角色吗？此操作将同时删除该角色的所有聊天记录，且不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 创建存档仓库实例
        final archiveRepository = await ChatArchiveRepository.create();

        // 先删除该角色的所有聊天存档
        final archives = await archiveRepository.getArchives(characterId);
        for (final archive in archives) {
          await archiveRepository.deleteArchive(characterId, archive.id);
        }

        // 再删除角色本身
        await _repository.deleteCharacter(characterId);
        await _loadCharacters();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }

  void _handleExport(BuildContext context, Character character) async {
    try {
      // 编码角色数据
      final encoded = CharacterCodec.encode(character);

      // 将字符串转换为UTF-8字节数组
      final bytes = utf8.encode(encoded);

      // 让用户选择保存位置
      final fileName = CharacterCodec.generateFileName(character.name);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes, // 提供字节数组
      );

      if (result == null) return; // 用户取消了保存

      if (!mounted) return;

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已将角色【${character.name}】导出到：$result'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '确定',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  Future<void> _navigateToChat(Character character) async {
    final config = await _modelConfigRepository.getConfig();
    if (!mounted) return;

    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置模型参数')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          character: character,
          modelConfig: config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasModelConfig) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              '请先配置模型参数',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在开始创建角色之前，需要先设置模型参数',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToModelConfig,
              icon: const Icon(Icons.settings),
              label: const Text('配置模型'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              _characters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '还没有角色',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => _handleEdit(context, null),
                            icon: const Icon(Icons.add),
                            label: const Text('创建角色'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _characters.length,
                      itemBuilder: (context, index) {
                        final character = _characters[index];
                        return CharacterCard(
                          name: character.name,
                          description: character.description,
                          avatarUrl: character.coverImageUrl,
                          tags: const [], // TODO: 添加标签支持
                          onEdit: () => _handleEdit(context, character),
                          onDelete: () => _handleDelete(context, character.id),
                          onExport: () => _handleExport(context, character),
                          onTap: () => _navigateToChat(character),
                        );
                      },
                    ),
              if (_characters.isNotEmpty)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () => _handleEdit(context, null),
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
