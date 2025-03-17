import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:my_app/data/models/multimodal_message.dart';
import 'package:my_app/core/network/api/multimodal_chat_api.dart';
import 'package:my_app/core/network/dio/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import '../widgets/chat_message_bubble.dart';
import '../widgets/loading_dots.dart';
import '../widgets/tip_card.dart';

class SpecialCharacterScreen extends StatefulWidget {
  const SpecialCharacterScreen({super.key});

  @override
  State<SpecialCharacterScreen> createState() => _SpecialCharacterScreenState();
}

class _SpecialCharacterScreenState extends State<SpecialCharacterScreen> {
  static const String _storageKey = 'special_character_chat_history';
  final Map<String, Uint8List> _imageCache = {};
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final _selectedImageNotifier = ValueNotifier<String?>(null);
  final _isLoadingNotifier = ValueNotifier<bool>(false);
  final _messagesNotifier = ValueNotifier<List<MultimodalMessage>>([]);
  final _errorNotifier = ValueNotifier<String?>(null);
  late final MultimodalChatApi _api;
  late final SharedPreferences _prefs;

  // 定义主题色
  static const Color starBlue = Color(0xFF6B8CFF);
  static const Color dreamPurple = Color(0xFFB277FF);
  static const Color darkBg = Color(0xFF1A1B1E);
  static const Color lightText = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _initApi();
  }

  Future<void> _initApi() async {
    _prefs = await SharedPreferences.getInstance();
    final dioClient = DioClient('', _prefs);
    _api = MultimodalChatApi(dioClient);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messagesJson = _prefs.getString(_storageKey);
      if (messagesJson != null) {
        final List<dynamic> decoded = json.decode(messagesJson);
        final messages =
            decoded.map((item) => MultimodalMessage.fromJson(item)).toList();
        _messagesNotifier.value = messages;
      }
    } catch (e) {
      print('加载历史消息失败: $e');
    }
  }

  Future<void> _saveMessages(List<MultimodalMessage> messages) async {
    try {
      final messagesJson =
          json.encode(messages.map((msg) => msg.toJson()).toList());
      await _prefs.setString(_storageKey, messagesJson);
    } catch (e) {
      print('保存历史消息失败: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _selectedImageNotifier.dispose();
    _isLoadingNotifier.dispose();
    _messagesNotifier.dispose();
    _errorNotifier.dispose();
    _imageCache.clear();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      _selectedImageNotifier.value = base64Encode(bytes);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // 由于列表是反向的，0 位置就是最新消息
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImageNotifier.value == null) return;

    // 保存当前状态以便出错时恢复
    final originalText = text;
    final originalImage = _selectedImageNotifier.value;

    // 立即清空输入
    _textController.clear();
    _selectedImageNotifier.value = null;

    // 立即滚动到底部，提供更好的视觉反馈
    _scrollToBottom();

    try {
      _isLoadingNotifier.value = true;
      _errorNotifier.value = null;

      final message = MultimodalMessage.createUserMessage(
        text: text,
        imageBase64: originalImage,
      );

      final messages = List<MultimodalMessage>.from(_messagesNotifier.value);

      // 如果已经有4条消息（2轮对话），移除最早的一轮
      if (messages.length >= 4) {
        messages.removeRange(0, 2);
      }

      messages.add(message);
      _messagesNotifier.value = List<MultimodalMessage>.from(messages);
      await _saveMessages(messages);

      final response = await _api.chat(
        message: text,
        history: messages,
      );

      // 立即关闭加载状态，因为已经收到响应
      _isLoadingNotifier.value = false;

      final cleanedText = response.text.trim().replaceAll(RegExp(r'\n+'), '\n');
      final aiMessage = MultimodalMessage.createModelMessage(
        text: cleanedText,
        generatedImageBase64:
            response.imageData?.isNotEmpty == true ? response.imageData : null,
      );

      messages.add(aiMessage);
      _messagesNotifier.value = List<MultimodalMessage>.from(messages);
      await _saveMessages(messages);
    } catch (e) {
      print('错误: $e');
      _isLoadingNotifier.value = false;

      // 发生错误时恢复输入并显示友好的错误提示
      _textController.text = originalText;
      _selectedImageNotifier.value = originalImage;
      _errorNotifier.value = '抱歉，请求失败了，请稍后重试';

      // 移除最后添加的用户消息（如果有的话）
      final messages = List<MultimodalMessage>.from(_messagesNotifier.value);
      if (messages.isNotEmpty) {
        messages.removeLast();
        _messagesNotifier.value = messages;
        await _saveMessages(messages);
      }
    }
  }

  Future<void> _clearHistory() async {
    _messagesNotifier.value = [];
    await _prefs.remove(_storageKey);
  }

  Future<void> _undoLastMessage() async {
    final messages = List<MultimodalMessage>.from(_messagesNotifier.value);
    if (messages.isNotEmpty) {
      // 如果至少有一轮对话(用户消息和AI回复)
      if (messages.length >= 2) {
        // 获取要撤销的用户消息
        final userMessage = messages[messages.length - 2];
        // 恢复用户的文本输入
        if (userMessage.text?.isNotEmpty ?? false) {
          _textController.text = userMessage.text!;
        }
        // 恢复用户的图片输入
        if (userMessage.imageData != null) {
          _selectedImageNotifier.value = userMessage.imageData!.data;
        }
        // 移除最后一轮对话
        messages.removeRange(messages.length - 2, messages.length);
      } else {
        // 只有一条消息的情况
        final message = messages.last;
        if (message.role == 'user') {
          // 如果是用户消息,恢复输入
          if (message.text?.isNotEmpty ?? false) {
            _textController.text = message.text!;
          }
          if (message.imageData != null) {
            _selectedImageNotifier.value = message.imageData!.data;
          }
        }
        messages.removeLast();
      }
      _messagesNotifier.value = messages;
      await _saveMessages(messages);
    }
  }

  Future<void> _saveImage(Uint8List imageData) async {
    try {
      final String fileName =
          'star_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = Platform.isIOS
          ? '${Directory.current.path}/$fileName'
          : '/storage/emulated/0/Download/$fileName';

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(imageData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '图片已保存到${Platform.isIOS ? '应用' : '下载'}文件夹',
              style: const TextStyle(color: lightText),
            ),
            backgroundColor: darkBg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '保存失败: $e',
              style: const TextStyle(color: lightText),
            ),
            backgroundColor: darkBg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                starBlue.withOpacity(0.2),
                dreamPurple.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: starBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
            ),
            color: lightText,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [starBlue, dreamPurple],
                ).createShader(bounds);
              },
              child: SvgPicture.asset(
                'assets/icons/four_point_star.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [starBlue, dreamPurple],
                ).createShader(bounds);
              },
              child: const Text(
                '星河画廊',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    starBlue.withOpacity(0.3),
                    dreamPurple.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: starBlue.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Text(
                'BETA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: lightText,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: lightText.withOpacity(0.8),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: starBlue.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: starBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [starBlue, dreamPurple],
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.sentiment_very_satisfied,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '开发者说',
                          style: TextStyle(
                            color: lightText.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '你说得对，但是《星河画廊》是由...\n算了，开发者很忙，帮助文档以后再写吧！\n\n点什么点，自己摸索去～',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: lightText.withOpacity(0.7),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [starBlue, dreamPurple],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '知道啦，不问了',
                              style: TextStyle(
                                color: lightText,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                darkBg,
                darkBg.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ValueListenableBuilder<String?>(
                      valueListenable: _errorNotifier,
                      builder: (context, error, child) {
                        if (error != null) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  error,
                                  style: TextStyle(
                                    color: lightText.withOpacity(0.8),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _errorNotifier.value = null,
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ValueListenableBuilder<List<MultimodalMessage>>(
                          valueListenable: _messagesNotifier,
                          builder: (context, messages, child) {
                            return Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: EdgeInsets.only(
                                    top: messages.isEmpty ? 16 : 80,
                                    bottom: 16,
                                  ),
                                  itemCount: messages.length +
                                      (_isLoadingNotifier.value ? 1 : 0) +
                                      1,
                                  itemBuilder: (context, index) {
                                    // 显示提示卡片
                                    if (index ==
                                        messages.length +
                                            (_isLoadingNotifier.value
                                                ? 1
                                                : 0)) {
                                      return const TipCard();
                                    }

                                    // 如果消息列表为空，显示空状态提示
                                    if (messages.isEmpty && index == 1) {
                                      return Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 32),
                                          child: Text(
                                            '开始你的创作之旅...',
                                            style: TextStyle(
                                              color: lightText.withOpacity(0.5),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final reverseIndex =
                                        (_isLoadingNotifier.value ? 1 : 0) +
                                            messages.length -
                                            1 -
                                            index;

                                    if (_isLoadingNotifier.value &&
                                        index == 0) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            left: 16,
                                            right: 64,
                                            top: 8,
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                darkBg.withOpacity(0.7),
                                                darkBg.withOpacity(0.9),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: starBlue.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: const LoadingDots(),
                                        ),
                                      );
                                    }

                                    return ChatMessageBubble(
                                      message: messages[reverseIndex],
                                      imageCache: _imageCache,
                                      onSaveImage: _saveImage,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<List<MultimodalMessage>>(
                      valueListenable: _messagesNotifier,
                      builder: (context, messages, child) {
                        if (messages.isEmpty) return const SizedBox.shrink();
                        return Positioned(
                          bottom: 16,
                          right: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: darkBg.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: starBlue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.undo,
                                        color: lightText.withOpacity(0.8),
                                        size: 20,
                                      ),
                                      onPressed: _undoLastMessage,
                                      tooltip: '撤销',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: starBlue.withOpacity(0.3),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: lightText.withOpacity(0.8),
                                        size: 20,
                                      ),
                                      onPressed: _clearHistory,
                                      tooltip: '清空历史',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: _selectedImageNotifier,
                builder: (context, selectedImage, child) {
                  if (selectedImage == null) return const SizedBox();
                  return Container(
                    height: 100,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: darkBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: starBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Image.memory(
                            base64Decode(selectedImage),
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: lightText),
                            onPressed: () {
                              _selectedImageNotifier.value = null;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkBg.withOpacity(0.95),
                  border: Border(
                    top: BorderSide(
                      color: starBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: darkBg.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.image,
                          color: lightText.withOpacity(0.8),
                        ),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: darkBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: starBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(
                              color: lightText,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: '描述你想要的图片...',
                              hintStyle: TextStyle(
                                color: lightText.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSubmit(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isLoadingNotifier,
                        builder: (context, isLoading, child) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLoading
                                    ? [
                                        starBlue.withOpacity(0.3),
                                        dreamPurple.withOpacity(0.3)
                                      ]
                                    : [starBlue, dreamPurple],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: lightText,
                                size: 20,
                              ),
                              onPressed: isLoading ? null : _handleSubmit,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
