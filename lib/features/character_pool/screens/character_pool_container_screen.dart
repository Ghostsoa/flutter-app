import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import './character_pool_screen.dart';
import './group_chat_list_screen.dart';
import './special_character_screen.dart';

class CharacterPoolContainerScreen extends StatefulWidget {
  const CharacterPoolContainerScreen({super.key});

  @override
  State<CharacterPoolContainerScreen> createState() =>
      _CharacterPoolContainerScreenState();
}

class _CharacterPoolContainerScreenState
    extends State<CharacterPoolContainerScreen>
    with SingleTickerProviderStateMixin {
  static const String _tabKey = 'character_pool_tab';
  bool _isGroupChat = false;
  late final PageController _pageController;
  bool _isInitialized = false;
  final _refreshNotifier = ValueNotifier<bool>(false);

  // 定义主题色，与多模态对话页面保持一致
  static const Color starBlue = Color(0xFF6B8CFF);
  static const Color dreamPurple = Color(0xFFB277FF);

  final List<Color> _gradientColors = [
    starBlue,
    dreamPurple,
    starBlue.withOpacity(0.8),
    dreamPurple.withOpacity(0.8),
    starBlue,
  ];

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

  Widget _buildShiningStarButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SpecialCharacterScreen(),
            ),
          );
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: _gradientColors,
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildTabButton(
                  label: '角色池',
                  isSelected: !_isGroupChat,
                  onTap: () => _switchTab(false),
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  label: '群聊',
                  isSelected: _isGroupChat,
                  onTap: () => _switchTab(true),
                ),
              ],
            ),
            _buildShiningStarButton(),
          ],
        ),
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
