import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import '../../../data/models/story.dart';
import '../../../data/models/story_message.dart';
import '../../../data/models/story_state.dart';
import '../../../data/local/shared_prefs/story_message_storage.dart';
import '../../../data/local/shared_prefs/story_state_storage.dart';
import '../../../data/local/shared_prefs/story_message_ui_storage.dart';
import '../../../core/network/api/story_api.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../services/message_manager.dart';
import '../widgets/status_card.dart';
import '../widgets/status_panel/status_panel.dart';
import '../services/audio_player_manager.dart';
import 'package:uuid/uuid.dart';

class RoleplayScreen extends StatefulWidget {
  final Story story;

  const RoleplayScreen({
    super.key,
    required this.story,
  });

  @override
  State<RoleplayScreen> createState() => _RoleplayScreenState();
}

class _RoleplayScreenState extends State<RoleplayScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  MessageManager? _messageManager;
  StoryApi? _api;
  late final StoryStateStorage _stateStorage;
  StoryState? _currentState;
  late final AudioPlayerManager _audioPlayer;

  @override
  void initState() {
    super.initState();
    _setFullScreen();
    _audioPlayer = AudioPlayerManager();
    _init();
  }

  Future<void> _init() async {
    if (_isInitializing) return;

    setState(() {
      _isLoading = true;
      _isInitializing = true;
      _isInitialized = false;
    });

    try {
      await _audioPlayer.init();
      final api = StoryApi();
      await api.init();
      final messageStorage = await StoryMessageStorage.init();
      final messageUIStorage = await StoryMessageUIStorage.init();
      _stateStorage = await StoryStateStorage.init();
      _messageManager = MessageManager(
        story: widget.story,
        storage: messageStorage,
        uiStorage: messageUIStorage,
        api: api,
      );

      _api = api;
      await _messageManager?.loadMessages();
      _currentState = await _stateStorage.getState(widget.story.id);

      if (_messageManager?.messages.isEmpty ?? true) {
        await _messageManager?.addSystemMessage(widget.story.opening);
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('初始化错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('初始化失败: ${e.toString()}')),
                TextButton(
                  onPressed: _init,
                  child:
                      const Text('重试', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _handleAction(String action) async {
    if (_isLoading) return;
    _messageController.text = action;
    await _handleSendMessage();
  }

  Future<void> _updateGameState(Map<String, dynamic> json) async {
    if (json['status_updates'] != null && json['next_actions'] != null) {
      final newState = StoryState(
        storyId: widget.story.id,
        statusUpdates: json['status_updates'] as Map<String, dynamic>,
        nextActions: List<Map<String, String>>.from(
          (json['next_actions'] as List)
              .map((action) => Map<String, String>.from(action)),
        ),
        updatedAt: DateTime.now(),
      );
      _currentState = newState;
      await _stateStorage.saveState(newState);
      setState(() {}); // 更新状态栏
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (!_isInitialized || _api == null) {
      if (!_isInitializing) {
        await _init();
        if (!_isInitialized || _api == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('初始化失败，请重试')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('系统正在初始化中，请稍后再试')),
        );
        return;
      }
    }

    final userInput = text;
    _messageController.clear();
    await _messageManager?.addUserMessage(text);

    setState(() => _isLoading = true);

    try {
      // 添加临时消息
      final tempId = const Uuid().v4();
      final now = DateTime.now();
      final tempMessage = StoryMessageUI(
        id: tempId,
        content: '正在思考...',
        type: StoryMessageUIType.modelContent,
        timestamp: now,
      );
      _messageManager?.messages.add(tempMessage);

      String? response;
      int retryCount = 0;
      const maxRetries = 3;
      bool success = false;

      while (retryCount < maxRetries && !success) {
        try {
          response = await _api!.chat(_messageManager!.storyMessages);
          // 验证返回的是有效的 JSON
          final json = jsonDecode(response);
          // 验证 JSON 结构是否完整
          if (json['content'] != null &&
              json['status_updates'] != null &&
              json['next_actions'] != null) {
            success = true;
          } else {
            throw Exception('JSON 结构不完整');
          }
        } catch (e) {
          debugPrint('第 ${retryCount + 1} 次尝试失败: $e');
          retryCount++;
          if (retryCount == maxRetries) {
            throw Exception('多次尝试后仍然失败');
          }
          await Future.delayed(const Duration(seconds: 1)); // 等待一秒后重试
        }
      }

      if (mounted && success && response != null) {
        setState(() {
          _messageManager?.messages.removeLast(); // 移除临时消息
        });

        // 更新游戏状态
        try {
          final json = jsonDecode(response);
          await _updateGameState(json);
        } catch (e) {
          debugPrint('解析状态更新失败: $e');
        }

        // 使用 MessageManager 的方法添加消息，这会触发蒸馏检查
        await _messageManager?.addAssistantMessage(response);
      } else {
        throw Exception('响应处理失败');
      }
    } catch (e) {
      debugPrint('对话错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取回复失败，请重试')),
        );
        setState(() {
          _messageManager?.messages.removeLast(); // 移除临时消息
          _messageManager?.messages.removeLast(); // 移除用户消息
          _messageManager?.storyMessages.removeLast(); // 移除存储的用户消息
          _messageController.text = userInput; // 恢复用户输入
        });
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUndo() async {
    if (_messageManager?.messages.isEmpty ?? true) return;

    // 移除最后两条消息（AI回复和用户输入）
    setState(() {
      if (_messageManager!.messages.isNotEmpty) {
        _messageManager!.messages.removeLast();
        if (_messageManager!.messages.isNotEmpty) {
          _messageManager!.messages.removeLast();
        }
      }
      if (_messageManager!.storyMessages.isNotEmpty) {
        _messageManager!.storyMessages.removeLast();
        if (_messageManager!.storyMessages.isNotEmpty) {
          _messageManager!.storyMessages.removeLast();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 返回按钮
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 12),
                  // 状态信息
                  if (_currentState?.statusUpdates != null)
                    Expanded(
                      child: StatusCard(
                        statusUpdates: _currentState!.statusUpdates,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 背景图
          if (widget.story.backgroundImagePath != null)
            Positioned.fill(
              child: Image.file(
                File(widget.story.backgroundImagePath!),
                fit: BoxFit.cover,
                cacheWidth: null,
                cacheHeight: null,
                gaplessPlayback: true,
                isAntiAlias: true,
                filterQuality: FilterQuality.high,
                opacity: const AlwaysStoppedAnimation(0.95),
              ),
            ),
          // 渐变遮罩
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.1), // 顶部使用白色增加亮度
                    Colors.black.withOpacity(0.1), // 中部极轻微的黑色
                    Colors.black.withOpacity(0.3), // 底部轻微的黑色以保持文字可读
                  ],
                  stops: const [0.0, 0.5, 0.9], // 调整渐变过渡点
                ),
              ),
            ),
          ),
          // 内容
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: _messageManager!.messages.length,
                    itemBuilder: (context, index) {
                      final message = _messageManager!.messages[
                          _messageManager!.messages.length - 1 - index];
                      return MessageBubble(
                        message: message,
                        accentColor: const Color(0xFF64B5F6),
                        onActionSelected: _handleAction,
                        audioPlayer: _audioPlayer,
                      );
                    },
                  ),
                ),
                if (_currentState?.statusUpdates != null)
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.6,
                              minChildSize: 0.3,
                              maxChildSize: 0.9,
                              builder: (context, scrollController) {
                                return StatusPanel(
                                  statusUpdates: _currentState!.statusUpdates,
                                  scrollController: scrollController,
                                );
                              },
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 16,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '状态面板',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ChatInputBar(
                  controller: _messageController,
                  isLoading: _isLoading,
                  onSend: _handleSendMessage,
                  accentColor: const Color(0xFF64B5F6),
                  onUndo: _messageManager?.messages.length != null &&
                          _messageManager!.messages.length >= 2
                      ? _handleUndo
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
