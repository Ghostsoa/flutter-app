import 'package:flutter/material.dart';
import 'dart:ui';

class GroupChatInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const GroupChatInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  State<GroupChatInput> createState() => _GroupChatInputState();
}

class _GroupChatInputState extends State<GroupChatInput>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  bool _isComposing = false;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));
  }

  void _handleFocusChange() {
    setState(() {});
  }

  void _handleTextChange() {
    final isComposing = widget.controller.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _insertParentheses(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start == -1 ? 0 : selection.start;
    final end = selection.end == -1 ? 0 : selection.end;

    final newText = text.replaceRange(start, end, '()');
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : theme.colorScheme.onSurface.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 200),
                    tween: Tween<double>(
                      begin: 0.0,
                      end: _focusNode.hasFocus ? 1.0 : 0.0,
                    ),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () => _insertParentheses(widget.controller),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '说点什么...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.6),
                          height: 1.4,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) {
                        if (_isComposing && !widget.isLoading) {
                          widget.onSend();
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedBuilder(
                    animation: _sendButtonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _sendButtonScaleAnimation.value,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _isComposing
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5),
                                _isComposing
                                    ? theme.colorScheme.primary.withOpacity(0.8)
                                    : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _isComposing
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (!_isComposing || widget.isLoading)
                                  ? null
                                  : () {
                                      _sendButtonController.forward().then((_) {
                                        _sendButtonController.reverse();
                                      });
                                      widget.onSend();
                                    },
                              borderRadius: BorderRadius.circular(20),
                              child: widget.isLoading
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
                                      color: _isComposing
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant
                                              .withOpacity(0.4),
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
