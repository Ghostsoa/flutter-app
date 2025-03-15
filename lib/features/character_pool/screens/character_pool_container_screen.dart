import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './character_pool_screen.dart';
import './group_chat_list_screen.dart';

class CharacterPoolContainerScreen extends StatefulWidget {
  const CharacterPoolContainerScreen({super.key});

  @override
  State<CharacterPoolContainerScreen> createState() =>
      _CharacterPoolContainerScreenState();
}

class _CharacterPoolContainerScreenState
    extends State<CharacterPoolContainerScreen> {
  static const String _tabKey = 'character_pool_tab';
  bool _isGroupChat = false;
  late final PageController _pageController;
  bool _isInitialized = false;
  final _refreshNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    final prefs = await SharedPreferences.getInstance();
    final isGroupChat = prefs.getBool(_tabKey) ?? false;
    if (mounted) {
      setState(() {
        _isGroupChat = isGroupChat;
        _isInitialized = true;
        _pageController = PageController(initialPage: isGroupChat ? 1 : 0);
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _pageController.dispose();
    }
    _refreshNotifier.dispose();
    super.dispose();
  }

  Future<void> _saveTab(bool isGroupChat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tabKey, isGroupChat);
  }

  void _handlePageChanged(int page) {
    final isGroupChat = page == 1;
    setState(() {
      _isGroupChat = isGroupChat;
    });
    _saveTab(isGroupChat);
  }

  void _switchTab(bool isGroupChat) {
    setState(() {
      _isGroupChat = isGroupChat;
      _pageController.animateToPage(
        isGroupChat ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    _saveTab(isGroupChat);
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色池'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton(
                  label: '普通',
                  isSelected: !_isGroupChat,
                  onTap: () => _switchTab(false),
                ),
                _buildTabButton(
                  label: '群聊',
                  isSelected: _isGroupChat,
                  onTap: () => _switchTab(true),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _refreshNotifier,
        builder: (context, _, child) => PageView(
          controller: _pageController,
          onPageChanged: _handlePageChanged,
          children: [
            CharacterPoolScreen(
              key: ValueKey('normal_${_refreshNotifier.value}'),
            ),
            GroupChatListScreen(
              key: ValueKey('group_chat_${_refreshNotifier.value}'),
            ),
          ],
        ),
      ),
    );
  }
}
