import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api/customer_service_api.dart';

class Message {
  final bool isUser;
  final String content;
  final DateTime timestamp;

  Message({
    required this.isUser,
    required this.content,
    required this.timestamp,
  });
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<Message> _messages = [];
  bool _isLoading = false;
  CustomerServiceApi? _api;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _initApi();
    _messageController.addListener(() {
      setState(() {
        _isComposing = _messageController.text.isNotEmpty;
      });
    });
  }

  Future<void> _initApi() async {
    _api = await CustomerServiceApi.getInstance();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleUrlTap(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开链接：$url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败：$e')),
        );
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _api == null) return;

    // 添加用户消息
    setState(() {
      _messages.add(Message(
        isUser: true,
        content: content,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    String aiResponse = '';
    try {
      await for (final chunk in _api!.chat(content)) {
        if (!mounted) break;
        aiResponse += chunk;
        setState(() {
          // 更新或添加AI回复
          if (_messages.length > 1 && !_messages.last.isUser) {
            _messages[_messages.length - 1] = Message(
              isUser: false,
              content: aiResponse,
              timestamp: DateTime.now(),
            );
          } else {
            _messages.add(Message(
              isUser: false,
              content: aiResponse,
              timestamp: DateTime.now(),
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMessage(Message message, ThemeData theme) {
    final content = message.content;

    // 如果是用户消息或者内容不包含URL，使用普通文本显示
    if (message.isUser) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: MarkdownBody(
                  data: content,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      _handleUrlTap(href);
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    a: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    code: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      fontFamily: 'monospace',
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    blockquote: TextStyle(
                      color:
                          theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 4,
                        ),
                      ),
                    ),
                    listBullet: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  selectable: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('智能客服'),
            Text(
              '单轮对话，不保存历史记录',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 欢迎消息
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '你好！我是小懿AI的智能客服助手。请问有什么可以帮助你的吗？',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    // 消息列表
                    ...List.generate(
                      _messages.length,
                      (index) => _buildMessage(_messages[index], theme),
                    ),
                    // 底部间距
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 120,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? theme.colorScheme.primary.withOpacity(0.5)
                                : theme.colorScheme.outline.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: '请输入您的问题...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (_isComposing) _handleSendMessage();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isComposing
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _isComposing
                              ? Colors.transparent
                              : theme.colorScheme.outline.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (_isLoading || !_isComposing)
                              ? null
                              : _handleSendMessage,
                          borderRadius: BorderRadius.circular(22),
                          child: _isLoading
                              ? Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _isComposing
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  size: 20,
                                  color: _isComposing
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.6),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
