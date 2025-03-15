import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/character_card.dart';
import './edit_character_screen.dart';
import '../../../data/models/character.dart';
import '../../../data/repositories/character_repository.dart';
import '../../../core/utils/character_codec.dart';
import '../../chat/screens/chat_screen.dart';
import 'dart:convert';

class CharacterPoolScreen extends StatefulWidget {
  const CharacterPoolScreen({super.key});

  @override
  State<CharacterPoolScreen> createState() => _CharacterPoolScreenState();
}

class _CharacterPoolScreenState extends State<CharacterPoolScreen> {
  late final CharacterRepository _repository;
  List<Character> _characters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repository = await CharacterRepository.create();
    await _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
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
          SnackBar(content: Text('加载失败：$e')),
        );
        setState(() => _isLoading = false);
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
    final needRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          character: character,
          modelConfig: character.toModelConfig(),
        ),
      ),
    );

    // 如果返回true，说明需要刷新列表
    if (needRefresh == true && mounted) {
      await _loadCharacters();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有创建任何角色',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮开始创建角色',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const EditCharacterScreen(),
                  ),
                );
                if (result == true && mounted) {
                  await _loadCharacters();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('创建角色'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: _characters.length,
          itemBuilder: (context, index) {
            final character = _characters[index];
            return CharacterCard(
              character: character,
              onTap: () => _navigateToChat(character),
              onEdit: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => EditCharacterScreen(
                      character: character,
                    ),
                  ),
                );

                if (result == true) {
                  await _loadCharacters();
                }
              },
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('删除角色'),
                    content: Text('确定要删除角色【${character.name}】吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _repository.deleteCharacter(character.id);
                  await _loadCharacters();
                }
              },
              onExport: () => _handleExport(context, character),
            );
          },
        ),
        if (_characters.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'character_pool_fab',
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const EditCharacterScreen(),
                  ),
                );
                if (result == true && mounted) {
                  await _loadCharacters();
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}
