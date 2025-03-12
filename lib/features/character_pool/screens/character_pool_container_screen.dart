import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './character_pool_screen.dart';
import './model_config_screen.dart';
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
    super.dispose();
  }

  Future<void> _saveTab(bool isGroupChat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tabKey, isGroupChat);
  }

  void _navigateToModelConfig() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModelConfigScreen(),
      ),
    );
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '模型配置',
            onPressed: _navigateToModelConfig,
          ),
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
      body: PageView(
        controller: _pageController,
        onPageChanged: _handlePageChanged,
        children: const [
          CharacterPoolScreen(key: ValueKey('normal')),
          GroupChatListScreen(key: ValueKey('group_chat')),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == '普通' ? Icons.person_outline : Icons.groups_outlined,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
