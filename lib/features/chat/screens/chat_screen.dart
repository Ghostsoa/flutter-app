import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/character.dart';
import '../../../data/models/model_config.dart';
import '../../../data/models/chat_archive.dart';
import '../../../data/repositories/character_repository.dart';
import '../../../data/repositories/model_config_repository.dart';
import '../../../data/repositories/chat_archive_repository.dart';
import '../../../core/network/api/chat_api.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_list.dart';
import 'dart:io';

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
  late Character _character;
  late ModelConfig _modelConfig;
  late final CharacterRepository _characterRepository;
  late final ModelConfigRepository _modelConfigRepository;
  late final ChatArchiveRepository _archiveRepository;
  List<ChatArchive> _archives = [];
  ChatArchive? _currentArchive;
  String _currentResponse = '';

  @override
  void initState() {
    super.initState();
    _character = widget.character;
    _modelConfig = widget.modelConfig;
    _initRepositories();
    // 设置为全屏模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  Future<void> _initRepositories() async {
    _characterRepository = await CharacterRepository.create();
    _modelConfigRepository = await ModelConfigRepository.create();
    _archiveRepository = await ChatArchiveRepository.create();

    // 获取最新的角色数据
    try {
      final latestCharacter =
          await _characterRepository.getCharacterById(_character.id);
      if (latestCharacter != null && mounted) {
        setState(() => _character = latestCharacter);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载角色信息失败：$e')),
        );
      }
    }

    await _loadArchives();
  }

  Future<void> _loadArchives() async {
    try {
      final archives = await _archiveRepository.getArchives(_character.id);
      if (mounted) {
        final lastArchiveId =
            await _archiveRepository.getLastArchiveId(_character.id);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载存档失败：$e')),
        );
      }
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
        final archive = await _archiveRepository.createArchive(
          _character.id,
          name,
        );
        if (mounted) {
          setState(() {
            _archives.add(archive);
            _currentArchive = archive;
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
                          await _archiveRepository.deleteArchive(
                            _character.id,
                            archive.id,
                          );
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
      await _archiveRepository.saveLastArchiveId(
          _character.id, selectedArchive.id);
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
    super.dispose();
  }

  Future<void> _handleCharacterUpdated(Character character) async {
    try {
      setState(() {
        _character = character;
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
      // 重新获取最新的模型配置
      final updatedConfig = await _modelConfigRepository.getConfig();
      if (updatedConfig != null && mounted) {
        setState(() {
          _modelConfig = updatedConfig;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新模型配置失败：$e')),
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
    // 隐藏输入法
    FocusScope.of(context).unfocus();

    try {
      // 添加用户消息
      final archive = await _archiveRepository.addMessage(
        _character.id,
        _currentArchive!.id,
        content,
        true,
      );

      if (mounted) {
        setState(() => _currentArchive = archive);
        await _scrollToBottom();
      }

      // 构建历史消息列表
      final messages = _currentArchive!.messages.map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        };
      }).toList();

      // 根据配置选择使用流式还是非流式请求
      if (_modelConfig.streamResponse) {
        // 使用流式请求
        String response = '';
        await for (final chunk in ChatApi.instance.sendStreamChatRequest(
          character: _character,
          modelConfig: _modelConfig,
          messages: messages,
        )) {
          response += chunk;
          if (mounted) {
            setState(() => _currentResponse = response);
          }
        }

        // 保存完整的响应
        if (mounted) {
          final updatedArchive = await _archiveRepository.addMessage(
            _character.id,
            _currentArchive!.id,
            response,
            false,
          );
          setState(() {
            _currentArchive = updatedArchive;
            _currentResponse = '';
            _isLoading = false;
          });
          await _archiveRepository.saveLastArchiveId(
              _character.id, updatedArchive.id);
          await _scrollToBottom();
        }
      } else {
        // 使用非流式请求
        String response = '';
        await for (final segment in ChatApi.instance.sendChatRequest(
          character: _character,
          modelConfig: _modelConfig,
          messages: messages,
        )) {
          if (segment.startsWith('[MESSAGE]')) {
            // 这是一个新的消息段，需要创建新的气泡
            final messageContent = segment.substring(9); // 移除 [MESSAGE] 标记
            final updatedArchive = await _archiveRepository.addMessage(
              _character.id,
              _currentArchive!.id,
              messageContent,
              false,
            );
            if (mounted) {
              setState(() {
                _currentArchive = updatedArchive;
              });
              await _scrollToBottom();
              // 添加延时效果
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } else if (segment.startsWith('[STATUS]')) {
            // 这是一个带状态信息的消息
            final content = segment.substring(7); // 移除 [STATUS] 标记
            final statusEndIndex = content.indexOf('[CONTENT]');
            if (statusEndIndex != -1) {
              final statusInfo = content.substring(0, statusEndIndex);
              final messageContent =
                  content.substring(statusEndIndex + 9); // 移除 [CONTENT] 标记

              final updatedArchive = await _archiveRepository.addMessage(
                _character.id,
                _currentArchive!.id,
                messageContent,
                false,
                statusInfo: statusInfo,
              );
              if (mounted) {
                setState(() {
                  _currentArchive = updatedArchive;
                });
                await _scrollToBottom();
              }
            }
          } else {
            // 普通模式，累积完整响应
            response += segment;
          }
        }

        // 如果是普通模式，保存完整的响应
        if (!_modelConfig.chunkResponse && response.isNotEmpty && mounted) {
          final updatedArchive = await _archiveRepository.addMessage(
            _character.id,
            _currentArchive!.id,
            response,
            false,
          );
          setState(() {
            _currentArchive = updatedArchive;
            _isLoading = false;
          });
          await _archiveRepository.saveLastArchiveId(
              _character.id, updatedArchive.id);
          await _scrollToBottom();
        } else {
          // 分段模式已经保存了所有消息，只需要更新状态
          setState(() {
            _isLoading = false;
          });
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
          if (updatedMessages.last.isUser) {
            updatedMessages.removeLast();
            await _archiveRepository.updateArchiveMessages(
              _character.id,
              _currentArchive!.id,
              updatedMessages,
            );
            setState(() {
              _currentArchive = _currentArchive!.copyWith(
                messages: updatedMessages,
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
      if (updatedMessages.isNotEmpty) {
        // 如果最后一条是 AI 的回复，删除它
        if (!updatedMessages.last.isUser) {
          updatedMessages.removeLast();
        }
        // 如果倒数第二条是用户的输入，也删除它
        if (updatedMessages.isNotEmpty && updatedMessages.last.isUser) {
          updatedMessages.removeLast();
        }
      }

      await _archiveRepository.updateArchiveMessages(
        _character.id,
        _currentArchive!.id,
        updatedMessages,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          image: _character.coverImageUrl != null
              ? DecorationImage(
                  image: _character.coverImageUrl!.startsWith('/')
                      ? FileImage(File(_character.coverImageUrl!))
                          as ImageProvider
                      : NetworkImage(_character.coverImageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(_character.backgroundOpacity),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
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
              ),
              ChatAppBar(
                character: _character,
                modelConfig: _modelConfig,
                onCharacterUpdated: _handleCharacterUpdated,
                onModelConfigUpdated: _handleModelConfigUpdated,
                onArchivePressed: _switchArchive,
                onUndoPressed: _handleUndo,
              ),
              ChatInput(
                controller: _messageController,
                isLoading: _isLoading,
                onSendPressed: _handleSendMessage,
              ),
            ] else
              Stack(
                children: [
                  // 空状态界面
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '没有可用的存档',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _createArchive,
                          icon: const Icon(Icons.add),
                          label: const Text('新建存档'),
                        ),
                      ],
                    ),
                  ),
                  // 只显示基本的顶部栏
                  Positioned(
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
                                icon: const Icon(Icons.arrow_back_ios_new,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                                splashRadius: 24,
                              ),
                              Expanded(
                                child: Text(
                                  _character.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // 只显示新建存档按钮
                              IconButton(
                                icon:
                                    const Icon(Icons.add, color: Colors.white),
                                onPressed: _createArchive,
                                splashRadius: 24,
                                tooltip: '新建存档',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
