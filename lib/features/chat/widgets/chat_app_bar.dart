import 'package:flutter/material.dart';
import '../../../data/models/character.dart';
import '../../../data/models/model_config.dart';
import '../../character_pool/screens/edit_character_screen.dart';
import '../../character_pool/screens/model_config_screen.dart';
import '../../../data/repositories/model_config_repository.dart';

class ChatAppBar extends StatelessWidget {
  final Character character;
  final ModelConfig modelConfig;
  final VoidCallback? onBackPressed;
  final Function(Character)? onCharacterUpdated;
  final Function(ModelConfig)? onModelConfigUpdated;
  final VoidCallback? onArchivePressed;
  final VoidCallback? onUndoPressed;
  final VoidCallback? onResetPressed;

  const ChatAppBar({
    super.key,
    required this.character,
    required this.modelConfig,
    this.onBackPressed,
    this.onCharacterUpdated,
    this.onModelConfigUpdated,
    this.onArchivePressed,
    this.onUndoPressed,
    this.onResetPressed,
  });

  Future<void> _showSettingsMenu(BuildContext context) async {
    // 先取消当前的焦点
    FocusScope.of(context).unfocus();

    final theme = Theme.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '设置',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
            ListTile(
              leading: Icon(
                Icons.settings_outlined,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                '模型配置',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                modelConfig.model,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              onTap: () {
                Navigator.pop(context, 'model_config');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                '编辑角色',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                '编辑 ${character.name} 的设定',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              onTap: () {
                Navigator.pop(context, 'edit_character');
              },
            ),
            const SizedBox(height: 8),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 确保取消按钮点击后也不会对焦
                    FocusScope.of(context).unfocus();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;

    switch (result) {
      case 'model_config':
        final configResult = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ModelConfigScreen(),
          ),
        );
        if (configResult == true) {
          final repository = await ModelConfigRepository.create();
          final updatedConfig = await repository.getConfig();
          if (updatedConfig != null) {
            onModelConfigUpdated?.call(updatedConfig);
          }
        }
        // 确保返回后不会对焦
        FocusScope.of(context).unfocus();
        break;
      case 'edit_character':
        final editResult = await Navigator.of(context).push<Character>(
          MaterialPageRoute(
            builder: (context) => EditCharacterScreen(
              character: character,
            ),
          ),
        );
        if (editResult != null) {
          onCharacterUpdated?.call(editResult);
        }
        // 确保返回后不会对焦
        FocusScope.of(context).unfocus();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  splashRadius: 24,
                ),
                Expanded(
                  child: Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: onResetPressed,
                  splashRadius: 24,
                  tooltip: '重置对话',
                ),
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white),
                  onPressed: onUndoPressed,
                  splashRadius: 24,
                  tooltip: '撤销最近一轮对话',
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: onArchivePressed,
                  splashRadius: 24,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showSettingsMenu(context),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
