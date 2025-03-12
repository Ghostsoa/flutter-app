import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../data/models/group_chat.dart';
import '../../../data/models/group_chat_role.dart';
import '../../../data/models/group_chat_message.dart';
import '../../../data/repositories/group_chat_history_repository.dart';
import '../../../core/network/api/group_chat_api.dart';
import '../widgets/group_chat_header.dart';
import '../widgets/group_chat_input.dart';
import '../widgets/ui_message.dart';
import '../widgets/decision_controller.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupChat group;

  const GroupChatScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messagesNotifier = ValueNotifier<List<GroupChatMessage>>([]);
  final _isLoadingNotifier = ValueNotifier<bool>(false);
  final _streamingContentNotifier = ValueNotifier<String>('');
  final _streamingRoleNotifier = ValueNotifier<String?>(null);
  final _isDecidingNotifier = ValueNotifier<bool>(false);
  final _selectedSpeakersNotifier = ValueNotifier<List<String>>([]);
  final Map<String, Image> _imageCache = {};
  final _canUndoNotifier = ValueNotifier<bool>(false);

  late final GroupChatHandler _messageHandler;
  late final GroupChatHistoryRepository _historyRepo;
  late final GroupChatMessageRepository _messageRepo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullScreen();
    _initServices();
    _precacheRoleImages();
  }

  Future<void> _initServices() async {
    _isLoadingNotifier.value = true;
    try {
      // 初始化API
      final api = await GroupChatApi.getInstance();

      // 初始化仓库
      _historyRepo = await GroupChatHistoryRepository.create();
      _messageRepo = await GroupChatMessageRepository.create();

      // 初始化消息处理器
      _messageHandler = GroupChatHandler(
        group: widget.group,
        api: api,
        historyRepo: _historyRepo,
        messageRepo: _messageRepo,
      );

      // 加载历史消息
      final messages = await _messageRepo.getMessages(widget.group.id);

      // 如果没有消息且有开场白，添加开场白
      if (messages.isEmpty && widget.group.greeting != null) {
        // 添加到UI消息列表
        await _messageRepo.addMessage(GroupChatMessage(
          groupId: widget.group.id,
          role: '系统',
          content: widget.group.greeting!,
          isGreeting: true, // 标记为开场白
        ));

        // 添加到XML历史记录
        await _historyRepo.appendHistory(
            widget.group.id, '系统', widget.group.greeting!);

        // 重新获取消息列表
        final updatedMessages = await _messageRepo.getMessages(widget.group.id);
        _messagesNotifier.value = updatedMessages;
        _canUndoNotifier.value = updatedMessages.isNotEmpty;
      } else {
        _messagesNotifier.value = messages;
        _canUndoNotifier.value = messages.isNotEmpty;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败：$e')),
        );
      }
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  void _precacheRoleImages() {
    for (final role in widget.group.roles) {
      if (role.avatarUrl != null && !_imageCache.containsKey(role.name)) {
        _imageCache[role.name] = Image.memory(
          base64Decode(role.avatarUrl!),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 80,
          cacheHeight: 80,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messagesNotifier.dispose();
    _isLoadingNotifier.dispose();
    _streamingContentNotifier.dispose();
    _streamingRoleNotifier.dispose();
    _isDecidingNotifier.dispose();
    _selectedSpeakersNotifier.dispose();
    _canUndoNotifier.dispose();
    _exitFullScreen();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setFullScreen();
    }
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0, // 因为列表是反转的,所以滚动到0就是底部
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _isLoadingNotifier.value = true;

    try {
      await _messageHandler.addUserMessage(content);
      final messages = await _messageRepo.getMessages(widget.group.id);
      _messagesNotifier.value = messages;
      _canUndoNotifier.value = messages.isNotEmpty;

      _isDecidingNotifier.value = true;
      if (widget.group.showDecisionProcess) {
        // 先获取发言者列表
        final speakers = await _messageHandler.decideNextSpeakers();
        // 确保在 setState 之前更新 ValueNotifier
        if (mounted) {
          _selectedSpeakersNotifier.value = List<String>.from(speakers);
        }
      } else {
        final speakers = await _messageHandler.decideNextSpeakers();
        await _startSpeaking(speakers);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$e')),
        );
      }
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  Future<void> _startSpeaking(List<String> speakers) async {
    _isDecidingNotifier.value = false;
    _selectedSpeakersNotifier.value = []; // 清空选择的发言者列表

    for (final speaker in speakers) {
      bool success = false;
      int retryCount = 0;
      Exception? lastError;

      while (!success && retryCount < 2) {
        try {
          if (widget.group.streamResponse) {
            _streamingRoleNotifier.value = speaker;
            _streamingContentNotifier.value = '';

            String buffer = '';
            await for (final chunk
                in _messageHandler.getRoleStreamResponse(speaker)) {
              buffer += chunk;
              _streamingContentNotifier.value = buffer;
              _scrollToBottom();
            }

            _streamingRoleNotifier.value = null;
            _streamingContentNotifier.value = '';

            final messages = await _messageRepo.getMessages(widget.group.id);
            _messagesNotifier.value = messages;
            _canUndoNotifier.value = messages.isNotEmpty;
            success = true;
          } else {
            final response = await _messageHandler.getRoleResponse(speaker);
            await _messageHandler.addRoleMessage(speaker, response);
            final messages = await _messageRepo.getMessages(widget.group.id);
            _messagesNotifier.value = messages;
            _canUndoNotifier.value = messages.isNotEmpty;
            success = true;
          }
        } catch (e) {
          lastError = e as Exception;
          retryCount++;
          if (retryCount < 2) {
            // 等待一秒后无感重试
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      // 只有在最终失败时才显示错误提示
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${speaker}发言失败：$lastError')),
        );
      }

      _scrollToBottom();
    }

    // 所有角色发言完成后,检查是否需要蒸馏
    if (await _messageHandler.shouldDistill()) {
      await _messageHandler.distillHistory();
      final messages = await _messageRepo.getMessages(widget.group.id);
      _messagesNotifier.value = messages;
      _canUndoNotifier.value = messages.isNotEmpty;
    }
  }

  Future<void> _handleRoleClick(GroupChatRole role) async {
    _isLoadingNotifier.value = true;

    bool success = false;
    int retryCount = 0;
    Exception? lastError;

    while (!success && retryCount < 2) {
      try {
        if (widget.group.streamResponse) {
          // 初始化流式消息
          _streamingRoleNotifier.value = role.name;
          _streamingContentNotifier.value = '';

          String buffer = '';
          await for (final chunk
              in _messageHandler.getRoleStreamResponse(role.name)) {
            buffer += chunk;
            _streamingContentNotifier.value = buffer;
            _scrollToBottom();
          }

          // 清除流式消息
          _streamingRoleNotifier.value = null;
          _streamingContentNotifier.value = '';

          // 更新消息列表
          final messages = await _messageRepo.getMessages(widget.group.id);
          _messagesNotifier.value = messages;
          success = true;
        } else {
          // 非流式响应
          final response = await _messageHandler.getRoleResponse(role.name);
          await _messageHandler.addRoleMessage(role.name, response);

          // 更新消息列表
          final messages = await _messageRepo.getMessages(widget.group.id);
          _messagesNotifier.value = messages;
          success = true;
        }
      } catch (e) {
        lastError = e as Exception;
        retryCount++;
        if (retryCount < 2) {
          // 等待一秒后无感重试
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    // 只有在最终失败时才显示错误提示
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${role.name}发言失败：$lastError')),
      );
    }

    _scrollToBottom();
    _streamingRoleNotifier.value = null;
    _streamingContentNotifier.value = '';
    _isLoadingNotifier.value = false;
  }

  Future<void> _handleUndo() async {
    if (_isLoadingNotifier.value) return;

    try {
      _isLoadingNotifier.value = true;

      // 获取最后一条消息
      final messages = await _messageRepo.getMessages(widget.group.id);
      if (messages.isEmpty) return;

      final lastMessage = messages.last;

      // 如果是用户消息，将内容恢复到输入框
      if (lastMessage.role == 'user') {
        _messageController.text = lastMessage.content;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: lastMessage.content.length),
        );
      }

      // 从消息列表和历史记录中移除最后一条消息
      await _messageRepo.removeLastMessage(widget.group.id);
      await _historyRepo.removeLastMessage(widget.group.id);

      // 更新消息列表
      final updatedMessages = await _messageRepo.getMessages(widget.group.id);
      _messagesNotifier.value = updatedMessages;
      _canUndoNotifier.value = updatedMessages.isNotEmpty;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撤销失败：$e')),
        );
      }
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  Future<void> _handleReset() async {
    if (_isLoadingNotifier.value) return;

    try {
      _isLoadingNotifier.value = true;

      // 清空所有消息和历史记录
      await _messageHandler.clearAll();

      // 如果有开场白，重新添加
      if (widget.group.greeting != null) {
        // 添加到UI消息列表
        await _messageRepo.addMessage(GroupChatMessage(
          groupId: widget.group.id,
          role: '系统',
          content: widget.group.greeting!,
          isGreeting: true,
        ));

        // 添加到XML历史记录
        await _historyRepo.appendHistory(
          widget.group.id,
          '系统',
          widget.group.greeting!,
        );
      }

      // 更新消息列表
      final messages = await _messageRepo.getMessages(widget.group.id);
      _messagesNotifier.value = messages;
      _canUndoNotifier.value = messages.isNotEmpty;

      // 清空输入框
      _messageController.clear();

      // 滚动到底部
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重置失败：$e')),
        );
      }
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (widget.group.backgroundImageData != null)
            Hero(
              tag: 'group-background-${widget.group.id}',
              child: Image.memory(
                base64Decode(widget.group.backgroundImageData!),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _canUndoNotifier,
                builder: (context, canUndo, _) {
                  return GroupChatHeader(
                    group: widget.group,
                    onRoleClick: _handleRoleClick,
                    imageCache: _imageCache,
                    onUndo: _handleUndo,
                    onReset: _handleReset,
                    canUndo: canUndo,
                  );
                },
              ),
              Expanded(
                child: _ChatMessageList(
                  messagesNotifier: _messagesNotifier,
                  streamingContentNotifier: _streamingContentNotifier,
                  streamingRoleNotifier: _streamingRoleNotifier,
                  isDecidingNotifier: _isDecidingNotifier,
                  scrollController: _scrollController,
                  group: widget.group,
                  imageCache: _imageCache,
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _isDecidingNotifier,
                  builder: (context, isDeciding, _) {
                    if (!isDeciding) return const SizedBox();
                    return ValueListenableBuilder<List<String>>(
                      valueListenable: _selectedSpeakersNotifier,
                      builder: (context, selectedSpeakers, _) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DecisionController(
                            showDecisionProcess:
                                widget.group.showDecisionProcess,
                            allRoles: widget.group.roles,
                            selectedSpeakers: selectedSpeakers,
                            onSpeakersChanged: (speakers) {
                              if (!listEquals(
                                  speakers, _selectedSpeakersNotifier.value)) {
                                _selectedSpeakersNotifier.value =
                                    List<String>.from(speakers);
                              }
                            },
                            onConfirm: () => _startSpeaking(selectedSpeakers),
                            imageCache: _imageCache,
                          ),
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _isLoadingNotifier,
                  builder: (context, isLoading, _) {
                    return GroupChatInput(
                      controller: _messageController,
                      isLoading: isLoading,
                      onSend: _handleSendMessage,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  final ValueNotifier<List<GroupChatMessage>> messagesNotifier;
  final ValueNotifier<String> streamingContentNotifier;
  final ValueNotifier<String?> streamingRoleNotifier;
  final ValueNotifier<bool> isDecidingNotifier;
  final ScrollController scrollController;
  final GroupChat group;
  final Map<String, Image> imageCache;

  const _ChatMessageList({
    required this.messagesNotifier,
    required this.streamingContentNotifier,
    required this.streamingRoleNotifier,
    required this.isDecidingNotifier,
    required this.scrollController,
    required this.group,
    required this.imageCache,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<GroupChatMessage>>(
      valueListenable: messagesNotifier,
      builder: (context, messages, _) {
        return ValueListenableBuilder<String>(
          valueListenable: streamingContentNotifier,
          builder: (context, streamingContent, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: streamingRoleNotifier,
              builder: (context, streamingRole, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: isDecidingNotifier,
                  builder: (context, isDeciding, _) {
                    final displayMessages =
                        List<GroupChatMessage>.from(messages);
                    if (streamingRole != null) {
                      displayMessages.add(GroupChatMessage(
                        groupId: group.id,
                        role: streamingRole,
                        content: streamingContent,
                      ));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      reverse: true,
                      padding: EdgeInsets.fromLTRB(
                          16, 80, 16, isDeciding ? 200 : 90),
                      itemCount: displayMessages.length,
                      itemBuilder: (context, index) {
                        final message =
                            displayMessages[displayMessages.length - 1 - index];
                        final isStreaming = message.role == streamingRole;
                        final role = message.role == 'user'
                            ? null
                            : group.roles.firstWhere(
                                (r) => r.name == message.role,
                                orElse: () => group.roles.first,
                              );

                        return UiMessage(
                          key: isStreaming
                              ? const ValueKey('streaming_message')
                              : ValueKey(message.id),
                          content: message.content,
                          role: role,
                          isUser: message.role == 'user',
                          timestamp: message.createdAt,
                          imageCache: imageCache,
                          isGreeting: message.isGreeting,
                          isDistilled: message.isDistilled,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
