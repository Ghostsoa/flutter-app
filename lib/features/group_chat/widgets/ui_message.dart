import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../data/models/group_chat_role.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 角色头像组件,使用const构造函数来缓存头像
class RoleAvatar extends StatelessWidget {
  final GroupChatRole role;

  const RoleAvatar({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ClipOval(
            child: role.avatarUrl != null
                ? Image.memory(
                    base64Decode(role.avatarUrl!),
                    fit: BoxFit.cover,
                    // 添加缓存配置
                    cacheWidth: 64,
                    cacheHeight: 64,
                    gaplessPlayback: true,
                  )
                : Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            role.name,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class UiMessage extends StatelessWidget {
  final String content;
  final GroupChatRole? role;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, Image>? imageCache;
  final bool isGreeting;
  final bool isDistilled;
  final bool isLoading;

  const UiMessage({
    super.key,
    required this.content,
    this.role,
    required this.isUser,
    required this.timestamp,
    this.imageCache,
    this.isGreeting = false,
    this.isDistilled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedContent = content.trimRight();

    if (isGreeting) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '开场白',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MarkdownBody(
                data: trimmedContent,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                  code: TextStyle(
                    color: Colors.pink[100],
                    backgroundColor: Colors.transparent,
                    fontSize: 14,
                    fontFamily: 'JetBrains Mono',
                    height: 1.5,
                  ),
                  codeblockPadding: const EdgeInsets.all(16),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  blockquote: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: Colors.blue[200]!.withOpacity(0.5),
                        width: 4,
                      ),
                    ),
                  ),
                  blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  h1: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.7,
                  ),
                  h2: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.7,
                  ),
                  h3: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.7,
                  ),
                  listBullet: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                  ),
                  listIndent: 24,
                  listBulletPadding: const EdgeInsets.only(right: 8),
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  em: const TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  tableHead: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  tableBody: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                  ),
                  tableBorder: TableBorder.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                  tableCellsPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tableColumnWidth: const FlexColumnWidth(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isDistilled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '已对上述对话进行总结',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && role != null)
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: (role!.avatarUrl != null)
                        ? (imageCache?[role!.name] ??
                            Image.memory(
                              base64Decode(role!.avatarUrl!),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              cacheWidth: 64,
                              cacheHeight: 64,
                            ))
                        : Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role!.name.length > 3
                        ? '${role!.name.substring(0, 2)}...'
                        : role!.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.white.withOpacity(0.8)
                    : Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? _buildLoadingDots()
                  : MarkdownBody(
                      data: trimmedContent,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.5,
                          letterSpacing: 0.3,
                        ),
                        code: TextStyle(
                          color: isUser ? Colors.pink[900] : Colors.pink[100],
                          backgroundColor: Colors.transparent,
                          fontSize: 14,
                          fontFamily: 'JetBrains Mono',
                          height: 1.5,
                        ),
                        codeblockPadding: const EdgeInsets.all(16),
                        codeblockDecoration: BoxDecoration(
                          color: isUser
                              ? Colors.black.withOpacity(0.05)
                              : Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUser
                                ? Colors.black.withOpacity(0.1)
                                : Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        blockquote: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.5,
                          letterSpacing: 0.3,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              isUser
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.15),
                              isUser
                                  ? Colors.black.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isUser
                                  ? Colors.blue[900]!.withOpacity(0.5)
                                  : Colors.blue[200]!.withOpacity(0.5),
                              width: 4,
                            ),
                          ),
                        ),
                        blockquotePadding:
                            const EdgeInsets.fromLTRB(16, 12, 12, 12),
                        h1: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.7,
                        ),
                        h2: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.7,
                        ),
                        h3: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.7,
                        ),
                        listBullet: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white.withOpacity(0.8),
                          fontSize: 15,
                        ),
                        listIndent: 24,
                        listBulletPadding: const EdgeInsets.only(right: 8),
                        strong: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        em: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isUser
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        tableHead: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        tableBody: TextStyle(
                          color: isUser
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white.withOpacity(0.9),
                          fontSize: 15,
                        ),
                        tableBorder: TableBorder.all(
                          color: isUser
                              ? Colors.black.withOpacity(0.2)
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                        tableCellsPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        tableColumnWidth: const FlexColumnWidth(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              (isUser ? Colors.white : Colors.black).withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
