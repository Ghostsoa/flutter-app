import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/character.dart';
import '../../../data/models/model_config.dart';
import '../../../data/models/chat_archive.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/character_repository.dart';
import '../../../data/repositories/chat_archive_repository.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_distilling_indicator.dart';
import '../widgets/chat_background.dart';
import '../widgets/chat_greeting.dart';
import '../services/chat_archive_manager.dart';
import '../services/chat_message_handler.dart';
import '../services/chat_audio_player_manager.dart';

class ChatScreen extends StatefulWidget {
  final Character character;
  final ModelConfig modelConfig;

  const ChatScreen({
    super.key,
    required this.character,
    required this.modelConfig,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isDistilling = false;
  late Character _character;
  late ModelConfig _modelConfig;
  late final CharacterRepository _characterRepository;
  late final ChatArchiveManager _archiveManager;
  late final ChatMessageHandler _messageHandler;
  late final ChatAudioPlayerManager _audioPlayerManager;
  List<ChatArchive> _archives = [];
  ChatArchive? _currentArchive;
  String _currentResponse = '';

  @override
  void initState() {
    super.initState();
    _character = widget.character;
    _modelConfig = widget.modelConfig;
    _initServices();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  Future<void> _initServices() async {
    _characterRepository = await CharacterRepository.create();
    final archiveRepository = await ChatArchiveRepository.create();

    _archiveManager = ChatArchiveManager(
      characterId: _character.id,
      repository: archiveRepository,
    );

    _audioPlayerManager = ChatAudioPlayerManager();
    await _audioPlayerManager.init();

    try {
      final latestCharacter =
          await _characterRepository.getCharacterById(_character.id);
      if (latestCharacter != null && mounted) {
        setState(() {
          _character = latestCharacter;
          _modelConfig = latestCharacter.toModelConfig();
        });

        _messageHandler = ChatMessageHandler(
          character: latestCharacter,
          modelConfig: latestCharacter.toModelConfig(),
        );
      } else {
        _messageHandler = ChatMessageHandler(
          character: _character,
          modelConfig: _modelConfig,
        );
      }
    } catch (e) {
      if (mounted) {
        // 如果获取最新角色信息失败，使用初始角色信息创建handler
        _messageHandler = ChatMessageHandler(
          character: _character,
          modelConfig: _modelConfig,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载角色信息失败：$e')),
        );
      }
    }

    await _loadArchives();
  }

  Future<void> _loadArchives() async {
    try {
      final archives = await _archiveManager.getArchives();
      if (mounted) {
        final lastArchiveId = await _archiveManager.getLastArchiveId();
        ChatArchive? currentArchive;

        if (lastArchiveId != null) {
          currentArchive = archives.firstWhere(
            (a) => a.id == lastArchiveId,
            orElse: () => archives.first,
          );
        } else if (archives.isNotEmpty) {
          currentArchive = archives.first;
        }

        setState(() {
          _archives = archives;
          _currentArchive = currentArchive;
        });
      }
    } catch (e) {
      // 静默处理加载存档错误
    }
  }

  Future<void> _createArchive() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('新建存档'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '存档名称',
              hintText: '输入存档名称',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );

    if (name != null) {
      try {
        // 创建一个新的存档
        final archive = await _archiveManager.createArchive(name);
        ChatArchive updatedArchive = archive;

        // 如果角色有开场白，添加开场白消息
        if (_character.greeting != null && _character.greeting!.isNotEmpty) {
          final greetingMessage =
              _messageHandler.createSystemMessage(_character.greeting!);
          final messages = [greetingMessage];
          await _archiveManager.updateArchiveMessages(
            archive.id,
            messages,
            uiMessages: messages,
          );
          updatedArchive = archive.copyWith(
            messages: messages,
            uiMessages: messages,
          );
        }

        // 自动切换到新存档
        await _archiveManager.saveLastArchiveId(archive.id);
        if (mounted) {
          await _loadArchives();
          setState(() {
            _currentArchive = updatedArchive;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建存档失败：$e')),
          );
        }
      }
    }
  }

  Future<void> _switchArchive() async {
    // 先取消当前的焦点
    FocusScope.of(context).unfocus();

    if (_archives.isEmpty) {
      _createArchive();
      return;
    }

    final archive = await showDialog<(ChatArchive?, bool)>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择存档'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _archives.length + 1,
              itemBuilder: (context, index) {
                if (index == _archives.length) {
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('新建存档'),
                    onTap: () => Navigator.pop(context, (null, true)),
                  );
                }

                final archive = _archives[index];
                return ListTile(
                  selected: archive.id == _currentArchive?.id,
                  leading: const Icon(Icons.history),
                  title: Text(archive.name),
                  subtitle: Text(
                    '${archive.messages.length}条消息',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('删除存档'),
                          content: Text('确定要删除存档"${archive.name}"吗？此操作不可恢复。'),
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

                      if (confirmed == true && mounted) {
                        try {
                          await _archiveManager.deleteArchive(archive.id);
                          if (mounted) {
                            setState(() {
                              _archives.removeWhere((a) => a.id == archive.id);
                              if (_currentArchive?.id == archive.id) {
                                _currentArchive = _archives.isNotEmpty
                                    ? _archives.first
                                    : null;
                              }
                            });
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('删除存档失败：$e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                  onTap: () => Navigator.pop(context, (archive, false)),
                );
              },
            ),
          ),
        );
      },
    );

    if (archive == null) return;

    final (selectedArchive, shouldCreateNew) = archive;
    if (shouldCreateNew) {
      _createArchive();
    } else if (mounted &&
        selectedArchive != null &&
        selectedArchive.id != _currentArchive?.id) {
      setState(() => _currentArchive = selectedArchive);
      await _archiveManager.saveLastArchiveId(selectedArchive.id);
      await _loadArchives(); // 重新加载以确保数据最新
    }
  }

  Future<void> _scrollToBottom() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    // 恢复系统UI设置
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayerManager.dispose();
    super.dispose();
  }

  Future<void> _handleCharacterUpdated(Character character) async {
    try {
      setState(() {
        _character = character;
        _modelConfig = character.toModelConfig();
        if (_currentArchive != null) {
          // 强制更新当前存档以应用新的样式
          _currentArchive = _currentArchive!.copyWith();
        }
      });
      // 强制重新加载存档以刷新UI
      await _loadArchives();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新角色信息失败：$e')),
        );
      }
    }
  }

  Future<void> _handleModelConfigUpdated(ModelConfig config) async {
    try {
      // 更新本地状态
      setState(() {
        _modelConfig = config;
      });

      // 使用copyWith更新角色对象
      final updatedCharacter = _character.copyWith(
        model: config.model,
        useAdvancedSettings: true, // 如果修改了配置，说明启用了高级设置
        temperature: config.temperature,
        topP: config.topP,
        presencePenalty: config.presencePenalty,
        frequencyPenalty: config.frequencyPenalty,
        maxTokens: config.maxTokens,
        streamResponse: config.streamResponse,
        enableDistillation: config.enableDistillation,
        distillationRounds: config.distillationRounds,
        distillationModel: config.distillationModel,
      );

      // 保存到数据库
      await _characterRepository.saveCharacter(updatedCharacter);

      // 更新本地角色状态
      setState(() {
        _character = updatedCharacter;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存模型配置失败：$e')),
        );
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isLoading) return;

    if (_currentArchive == null) {
      await _createArchive();
      if (_currentArchive == null) return;
    }

    setState(() => _isLoading = true);
    _messageController.clear();
    FocusScope.of(context).unfocus();

    try {
      final message = await _messageHandler.createUserMessage(content);
      final updatedMessages = [..._currentArchive!.messages, message];
      final updatedUiMessages = [..._currentArchive!.uiMessages, message];

      await _archiveManager.updateArchiveMessages(
        _currentArchive!.id,
        updatedMessages,
        uiMessages: updatedUiMessages,
      );

      if (mounted) {
        setState(() {
          _currentArchive = _currentArchive!.copyWith(
            messages: updatedMessages,
            uiMessages: updatedUiMessages,
          );
        });
        await _scrollToBottom();
      }

      final messages = _currentArchive!.messages.map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        };
      }).toList();

      if (_modelConfig.streamResponse) {
        String response = '';
        await for (final chunk
            in _messageHandler.sendStreamChatRequest(messages)) {
          response += chunk;
          if (mounted) {
            setState(() => _currentResponse = response);
          }
        }

        if (mounted) {
          final (cleanContent, statusInfo) =
              ChatMessage.extractStatusInfo(response);
          final aiMessage =
              _messageHandler.createAIMessage(cleanContent, statusInfo);
          final newMessages = [..._currentArchive!.messages, aiMessage];
          final newUiMessages = [..._currentArchive!.uiMessages, aiMessage];

          await _archiveManager.updateArchiveMessages(
            _currentArchive!.id,
            newMessages,
            uiMessages: newUiMessages,
          );

          setState(() {
            _currentArchive = _currentArchive!.copyWith(
              messages: newMessages,
              uiMessages: newUiMessages,
            );
            _currentResponse = '';
            _isLoading = false;
          });

          await _archiveManager.saveLastArchiveId(_currentArchive!.id);
          await _scrollToBottom();

          if (_modelConfig.enableDistillation &&
              newMessages.length >= _modelConfig.distillationRounds * 2) {
            await _performDistillation();
          }
        }
      } else {
        final response = await _messageHandler.sendChatRequest(messages);

        if (response.isNotEmpty && mounted) {
          final (cleanContent, statusInfo) =
              ChatMessage.extractStatusInfo(response);
          final aiMessage =
              _messageHandler.createAIMessage(cleanContent, statusInfo);
          final newMessages = [..._currentArchive!.messages, aiMessage];
          final newUiMessages = [..._currentArchive!.uiMessages, aiMessage];

          await _archiveManager.updateArchiveMessages(
            _currentArchive!.id,
            newMessages,
            uiMessages: newUiMessages,
          );

          setState(() {
            _currentArchive = _currentArchive!.copyWith(
              messages: newMessages,
              uiMessages: newUiMessages,
            );
            _isLoading = false;
          });

          await _archiveManager.saveLastArchiveId(_currentArchive!.id);
          await _scrollToBottom();

          if (_modelConfig.enableDistillation &&
              newMessages.length >= _modelConfig.distillationRounds * 2) {
            await _performDistillation();
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('响应异常')),
        );

        // 将用户输入恢复到输入框
        _messageController.text = content;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: content.length),
        );

        // 从记录中删除最后一条用户消息
        if (_currentArchive != null && _currentArchive!.messages.isNotEmpty) {
          final updatedMessages = _currentArchive!.messages.toList();
          final updatedUiMessages = _currentArchive!.uiMessages.toList();
          if (updatedMessages.last.isUser) {
            updatedMessages.removeLast();
            updatedUiMessages.removeLast();
            await _archiveManager.updateArchiveMessages(
              _currentArchive!.id,
              updatedMessages,
              uiMessages: updatedUiMessages,
            );
            setState(() {
              _currentArchive = _currentArchive!.copyWith(
                messages: updatedMessages,
                uiMessages: updatedUiMessages,
              );
            });
          }
        }
      }
    }
  }

  Future<void> _handleUndo() async {
    if (_currentArchive == null || _currentArchive!.messages.isEmpty) return;

    try {
      // 获取最后一轮对话的用户输入
      final messages = _currentArchive!.messages;
      final uiMessages = _currentArchive!.uiMessages;
      String? userInput;

      // 从后往前找到最近的一轮对话
      for (var i = messages.length - 1; i >= 0; i--) {
        if (messages[i].isUser) {
          userInput = messages[i].content;
          break;
        }
      }

      // 删除最后一轮对话
      final updatedMessages = messages.toList();
      final updatedUiMessages = uiMessages.toList();

      // 如果最后一条是 AI 的回复，删除它
      if (updatedMessages.isNotEmpty && !updatedMessages.last.isUser) {
        updatedMessages.removeLast();
        // 从 UI 消息中删除所有最后一轮的 AI 回复（可能有多条）
        while (updatedUiMessages.isNotEmpty && !updatedUiMessages.last.isUser) {
          updatedUiMessages.removeLast();
        }
      }

      // 如果倒数第二条是用户的输入，也删除它
      if (updatedMessages.isNotEmpty && updatedMessages.last.isUser) {
        updatedMessages.removeLast();
        updatedUiMessages.removeLast();
      }

      await _archiveManager.updateArchiveMessages(
        _currentArchive!.id,
        updatedMessages,
        uiMessages: updatedUiMessages,
      );

      if (mounted) {
        // 将用户的输入放回输入框
        if (userInput != null) {
          _messageController.text = userInput;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: userInput.length),
          );
        }

        setState(() {
          _currentArchive = _currentArchive!.copyWith(
            messages: updatedMessages,
            uiMessages: updatedUiMessages,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撤销失败：$e')),
        );
      }
    }
  }

  /// 执行上下文蒸馏
  Future<void> _performDistillation() async {
    if (!mounted) return;

    setState(() => _isDistilling = true);

    try {
      final distilledContent = await _messageHandler.distillContext(
        _currentArchive!.messages,
        _modelConfig.distillationModel,
      );

      final uiMessages =
          _currentArchive!.uiMessages.map((msg) => msg.copyWith()).toList();
      uiMessages.add(_messageHandler.createSystemMessage('系统已对以上对话进行了记忆整理'));

      final historyMessages = [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '[历史记忆]$distilledContent',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

      await _archiveManager.updateArchiveMessages(
        _currentArchive!.id,
        historyMessages,
        uiMessages: uiMessages,
      );

      if (mounted) {
        setState(() {
          _currentArchive = _currentArchive!.copyWith(
            messages: historyMessages,
            uiMessages: uiMessages,
          );
          _isDistilling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDistilling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记忆整理失败：$e')),
        );
      }
    }
  }

  Future<void> _handleMessageEdit(
      ChatMessage message, String newContent) async {
    if (_currentArchive == null) return;

    try {
      // 更新UI消息
      final updatedUiMessages = _currentArchive!.uiMessages.map((msg) {
        if (msg.id == message.id) {
          return msg.copyWith(content: newContent);
        }
        return msg;
      }).toList();

      // 更新实际消息
      final updatedMessages = _currentArchive!.messages.map((msg) {
        if (msg.id == message.id) {
          return msg.copyWith(content: newContent);
        }
        return msg;
      }).toList();

      await _archiveManager.updateArchiveMessages(
        _currentArchive!.id,
        updatedMessages,
        uiMessages: updatedUiMessages,
      );

      if (mounted) {
        setState(() {
          _currentArchive = _currentArchive!.copyWith(
            messages: updatedMessages,
            uiMessages: updatedUiMessages,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('编辑失败：$e')),
        );
      }
    }
  }

  Future<void> _handleReset() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要重置对话吗？这将清空所有对话记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (_currentArchive != null) {
        // 清空消息记录
        await _archiveManager.updateArchiveMessages(
          _currentArchive!.id,
          [],
          uiMessages: [],
        );

        setState(() {
          _currentArchive = _currentArchive!.copyWith(
            messages: [],
            uiMessages: [],
          );
        });

        // 如果有开场白，添加为系统消息
        if (_character.greeting != null && _character.greeting!.isNotEmpty) {
          final greetingMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: _character.greeting!,
            isUser: false,
            timestamp: DateTime.now(),
            isSystemMessage: true,
          );
          await _archiveManager.updateArchiveMessages(
            _currentArchive!.id,
            [greetingMessage],
            uiMessages: [greetingMessage],
          );

          setState(() {
            _currentArchive = _currentArchive!.copyWith(
              messages: [greetingMessage],
              uiMessages: [greetingMessage],
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重置失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ChatBackground(
        coverImageUrl: _character.coverImageUrl,
        backgroundOpacity: _character.backgroundOpacity,
        children: [
          if (_currentArchive != null) ...[
            ChatMessageList(
              controller: _scrollController,
              archive: _currentArchive!,
              characterImageUrl: _character.coverImageUrl,
              useMarkdown: _character.useMarkdown,
              userBubbleColor: _character.userBubbleColor,
              aiBubbleColor: _character.aiBubbleColor,
              userTextColor: _character.userTextColor,
              aiTextColor: _character.aiTextColor,
              streamingText: _currentResponse,
              messageFilter: (message) => !message.content.contains('[历史记忆]'),
              onMessageEdit: _handleMessageEdit,
              audioPlayer: _audioPlayerManager,
              greetingBuilder:
                  _character.greeting != null && _character.greeting!.isNotEmpty
                      ? (context) => ChatGreeting(
                            message: _character.greeting!,
                            useMarkdown: _character.useMarkdown,
                          )
                      : null,
            ),
            ChatDistillingIndicator(isDistilling: _isDistilling),
            ChatAppBar(
              character: _character,
              modelConfig: _modelConfig,
              characterRepository: _characterRepository,
              onCharacterUpdated: _handleCharacterUpdated,
              onModelConfigUpdated: _handleModelConfigUpdated,
              onArchivePressed: _switchArchive,
              onUndoPressed: _handleUndo,
              onResetPressed: _handleReset,
            ),
            ChatInput(
              controller: _messageController,
              isLoading: _isLoading,
              onSendPressed: _handleSendMessage,
            ),
          ] else
            ChatEmptyState(onCreateArchive: _createArchive),
        ],
      ),
    );
  }
}
