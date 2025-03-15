import 'package:flutter/material.dart';
import '../../../data/models/character.dart';
import '../../../data/models/model_config.dart';
import '../../character_pool/screens/edit_character_screen.dart';
import '../../../data/repositories/character_repository.dart';

class ChatAppBar extends StatelessWidget {
  final Character character;
  final ModelConfig modelConfig;
  final VoidCallback? onBackPressed;
  final Function(Character)? onCharacterUpdated;
  final Function(ModelConfig)? onModelConfigUpdated;
  final VoidCallback? onArchivePressed;
  final VoidCallback? onUndoPressed;
  final VoidCallback? onResetPressed;
  final CharacterRepository characterRepository;

  const ChatAppBar({
    super.key,
    required this.character,
    required this.modelConfig,
    required this.characterRepository,
    this.onBackPressed,
    this.onCharacterUpdated,
    this.onModelConfigUpdated,
    this.onArchivePressed,
    this.onUndoPressed,
    this.onResetPressed,
  });

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
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () async {
                    final editResult = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => EditCharacterScreen(
                          character: character,
                        ),
                      ),
                    );
                    if (editResult == true) {
                      final updatedCharacter = await characterRepository
                          .getCharacterById(character.id);
                      if (updatedCharacter != null) {
                        onCharacterUpdated?.call(updatedCharacter);
                        onModelConfigUpdated
                            ?.call(updatedCharacter.toModelConfig());
                      }
                    }
                  },
                  splashRadius: 24,
                  tooltip: '角色设置',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
