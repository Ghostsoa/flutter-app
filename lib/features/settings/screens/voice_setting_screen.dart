import 'package:flutter/material.dart';
import '../../../data/models/voice_setting.dart';
import '../../../data/local/shared_prefs/voice_setting_storage.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/network/api/tts_api.dart';

class VoiceSettingScreen extends StatefulWidget {
  const VoiceSettingScreen({super.key});

  @override
  State<VoiceSettingScreen> createState() => _VoiceSettingScreenState();
}

class VoiceInfo {
  final String id;
  final String name;
  final bool canPreview;

  const VoiceInfo({
    required this.id,
    required this.name,
    required this.canPreview,
  });
}

class _VoiceSettingScreenState extends State<VoiceSettingScreen> {
  late VoiceSettingStorage _storage;
  late TTSApi _ttsApi;
  VoiceSetting? _setting;
  VoiceSetting? _editingSetting;
  bool _isLoading = true;
  bool _hasChanges = false;
  final _audioPlayer = AudioPlayer();
  String? _playingVoiceId;

  // 音色列表
  final List<VoiceInfo> _voices = [
    // 可试听音色
    const VoiceInfo(id: 'female-shaonv', name: '少女', canPreview: true),
    const VoiceInfo(id: 'female-yujie', name: '御姐', canPreview: true),
    const VoiceInfo(id: 'female-chengshu', name: '成熟女性', canPreview: true),
    const VoiceInfo(id: 'female-tianmei', name: '甜美女性', canPreview: true),
    const VoiceInfo(id: 'male-qn-qingse', name: '青涩青年', canPreview: true),
    const VoiceInfo(id: 'male-qn-jingying', name: '精英青年', canPreview: true),
    const VoiceInfo(id: 'male-qn-badao', name: '霸道青年', canPreview: true),
    const VoiceInfo(id: 'presenter_male', name: '男性主持人', canPreview: true),
    const VoiceInfo(id: 'audiobook_male_2', name: '男性有声书2', canPreview: true),
    const VoiceInfo(id: 'audiobook_female_1', name: '女性有声书1', canPreview: true),
    const VoiceInfo(id: 'audiobook_female_2', name: '女性有声书2', canPreview: true),
    const VoiceInfo(id: 'bingjiao_didi', name: '病娇弟弟', canPreview: true),
    const VoiceInfo(id: 'tianxin_xiaoling', name: '甜心小玲', canPreview: true),
    const VoiceInfo(id: 'wumei_yujie', name: '妩媚御姐', canPreview: true),
    // 其他音色
    const VoiceInfo(id: 'male-qn-daxuesheng', name: '青年大学生', canPreview: false),
    const VoiceInfo(id: 'presenter_female', name: '女性主持人', canPreview: false),
    const VoiceInfo(id: 'audiobook_male_1', name: '男性有声书1', canPreview: false),
    const VoiceInfo(
        id: 'male-qn-qingse-jingpin', name: '青涩青年-beta', canPreview: false),
    const VoiceInfo(
        id: 'male-qn-jingying-jingpin', name: '精英青年-beta', canPreview: false),
    const VoiceInfo(
        id: 'male-qn-badao-jingpin', name: '霸道青年-beta', canPreview: false),
    const VoiceInfo(
        id: 'male-qn-daxuesheng-jingpin',
        name: '青年大学生-beta',
        canPreview: false),
    const VoiceInfo(
        id: 'female-shaonv-jingpin', name: '少女-beta', canPreview: false),
    const VoiceInfo(
        id: 'female-yujie-jingpin', name: '御姐-beta', canPreview: false),
    const VoiceInfo(
        id: 'female-chengshu-jingpin', name: '成熟女性-beta', canPreview: false),
    const VoiceInfo(
        id: 'female-tianmei-jingpin', name: '甜美女性-beta', canPreview: false),
    const VoiceInfo(id: 'clever_boy', name: '聪明男童', canPreview: false),
    const VoiceInfo(id: 'cute_boy', name: '可爱男童', canPreview: false),
    const VoiceInfo(id: 'lovely_girl', name: '萌萌女童', canPreview: false),
    const VoiceInfo(id: 'cartoon_pig', name: '卡通猪小琪', canPreview: false),
    const VoiceInfo(id: 'junlang_nanyou', name: '俊朗男友', canPreview: false),
    const VoiceInfo(id: 'chunzhen_xuedi', name: '纯真学弟', canPreview: false),
    const VoiceInfo(id: 'lengdan_xiongzhang', name: '冷淡学长', canPreview: false),
    const VoiceInfo(id: 'badao_shaoye', name: '霸道少爷', canPreview: false),
    const VoiceInfo(id: 'qiaopi_mengmei', name: '俏皮萌妹', canPreview: false),
    const VoiceInfo(id: 'diadia_xuemei', name: '嗲嗲学妹', canPreview: false),
    const VoiceInfo(id: 'danya_xuejie', name: '淡雅学姐', canPreview: false),
  ];

  // 情感参数列表
  final List<Map<String, String>> _emotions = [
    {'id': 'happy', 'name': '开心'},
    {'id': 'sad', 'name': '悲伤'},
    {'id': 'angry', 'name': '生气'},
    {'id': 'fearful', 'name': '恐惧'},
    {'id': 'disgusted', 'name': '厌恶'},
    {'id': 'surprised', 'name': '惊讶'},
    {'id': 'neutral', 'name': '平静'},
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _ttsApi = TTSApi();
    await _ttsApi.init();
    await _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = await VoiceSettingStorage.init();
    final setting = await _storage.getSetting();
    setState(() {
      _setting = setting;
      _editingSetting = setting;
      _isLoading = false;
      _hasChanges = false;
    });
  }

  void _updateEditingSetting(VoiceSetting newSetting) {
    setState(() {
      _editingSetting = newSetting;
      _hasChanges = true;
    });
  }

  Future<void> _saveSetting() async {
    if (!_hasChanges) return;

    setState(() => _isLoading = true);
    try {
      await _storage.saveSetting(_editingSetting!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要将所有设置恢复到默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _editingSetting = VoiceSetting.defaultSetting;
                _hasChanges = true;
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _getVoiceName(String voiceId) {
    return _voices
        .firstWhere(
          (v) => v.id == voiceId,
          orElse: () =>
              VoiceInfo(id: voiceId, name: voiceId, canPreview: false),
        )
        .name;
  }

  String _getEmotionName(String emotionId) {
    return _emotions.firstWhere(
      (e) => e['id'] == emotionId,
      orElse: () => {'id': emotionId, 'name': emotionId},
    )['name']!;
  }

  Future<void> _previewVoice(String voiceId) async {
    final voice = _voices.firstWhere((v) => v.id == voiceId);
    if (!voice.canPreview) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该音色暂不支持试听')),
        );
      }
      return;
    }

    try {
      // 如果正在播放同一个音色，就停止播放
      if (_playingVoiceId == voiceId) {
        await _audioPlayer.stop();
        setState(() => _playingVoiceId = null);
        return;
      }

      // 获取音色名称作为文件名
      final audioPath = 'assets/audio/voices/${voice.name}.mp3';

      // 设置音频源并播放
      setState(() => _playingVoiceId = voiceId);
      await _audioPlayer.setAsset(audioPath);
      await _audioPlayer.play();

      // 播放完成后重置状态
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() => _playingVoiceId = null);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('试听失败：$e')),
        );
        setState(() => _playingVoiceId = null);
      }
    }
  }

  // 修改音色选择列表中的播放按钮
  Widget _buildPlayButton(String voiceId) {
    final voice = _voices.firstWhere((v) => v.id == voiceId);
    if (!voice.canPreview) {
      return const SizedBox.shrink();
    }

    final isPlaying = _playingVoiceId == voiceId;
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
        color: isPlaying ? Theme.of(context).primaryColor : null,
      ),
      onPressed: () => _previewVoice(voiceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _setting == null || _editingSetting == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('语音设置'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _resetSettings,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('重置'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveSetting,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('保存'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 价格提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '文本转语音350小懿币/万字符',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 基础设置卡片
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '基础设置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 音色选择
                  _buildSettingItem(
                    context,
                    icon: Icons.record_voice_over_outlined,
                    title: '音色',
                    subtitle: _getVoiceName(_editingSetting!.voiceId),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPlayButton(_editingSetting!.voiceId),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _showVoiceSelector(context),
                  ),
                  const Divider(height: 24),
                  // 情感选择
                  _buildSettingItem(
                    context,
                    icon: Icons.emoji_emotions_outlined,
                    title: '情感',
                    subtitle: _getEmotionName(_editingSetting!.emotion),
                    onTap: () => _showEmotionSelector(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 参数调节卡片
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '参数调节',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 语速调节
                  _buildSliderSetting(
                    context,
                    icon: Icons.speed,
                    title: '语速',
                    value: _editingSetting!.speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) {
                      setState(() {
                        _editingSetting =
                            _editingSetting!.copyWith(speed: value);
                        _hasChanges = true;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // 音量调节
                  _buildSliderSetting(
                    context,
                    icon: Icons.volume_up_outlined,
                    title: '音量',
                    value: _editingSetting!.vol,
                    min: 0.1,
                    max: 10.0,
                    divisions: 99,
                    onChanged: (value) {
                      setState(() {
                        _editingSetting = _editingSetting!.copyWith(vol: value);
                        _hasChanges = true;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // 音调调节
                  _buildSliderSetting(
                    context,
                    icon: Icons.music_note_outlined,
                    title: '音调',
                    value: _editingSetting!.pitch.toDouble(),
                    min: -12,
                    max: 12,
                    divisions: 24,
                    valueFormat: (value) => value.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _editingSetting =
                            _editingSetting!.copyWith(pitch: value.round());
                        _hasChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 缓存设置卡片
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '缓存设置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showClearCacheDialog(context),
                        icon: const Icon(Icons.cleaning_services_outlined,
                            size: 18),
                        label: const Text('清除缓存'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSliderSetting(
                    context,
                    icon: Icons.storage_outlined,
                    title: '缓存条数',
                    value: _editingSetting!.cacheLimit.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 10,
                    valueFormat: (value) => value.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _editingSetting = _editingSetting!
                            .copyWith(cacheLimit: value.round());
                        _hasChanges = true;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 36, top: 8),
                    child: Text(
                      '* 缓存条数越大，缓存越多，但可能会占用更多内存',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 提示信息卡片
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '温馨提示',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BETA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    context,
                    '部分音色支持试听功能，可点击播放按钮预览',
                  ),
                  const SizedBox(height: 8),
                  _buildTipItem(
                    context,
                    '默认参数已经过优化调试，非必要情况下建议保持默认设置',
                  ),
                  const SizedBox(height: 8),
                  _buildTipItem(
                    context,
                    '切换模型会导致之前缓存丢失',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String Function(double)? valueFormat,
  }) {
    final theme = Theme.of(context);
    final formattedValue = valueFormat?.call(value) ?? value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.2),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: formattedValue,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  void _showVoiceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.record_voice_over_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '选择音色',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _voices.length,
                  itemBuilder: (context, index) {
                    final voice = _voices[index];
                    final isSelected = _editingSetting!.voiceId == voice.id;
                    return InkWell(
                      onTap: () {
                        if (_playingVoiceId != null) {
                          _audioPlayer.stop();
                          setState(() => _playingVoiceId = null);
                        }
                        Navigator.pop(context);
                        _updateEditingSetting(
                          _editingSetting!.copyWith(voiceId: voice.id),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                voice.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '当前',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            _buildPlayButton(voice.id),
                          ],
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
    );
  }

  void _showEmotionSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_emotions_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '选择情感',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _emotions.length,
                  itemBuilder: (context, index) {
                    final emotion = _emotions[index];
                    final isSelected =
                        _editingSetting!.emotion == emotion['id'];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _updateEditingSetting(
                          _editingSetting!.copyWith(emotion: emotion['id']),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                emotion['name']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '当前',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
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
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('清除缓存'),
          ],
        ),
        content: const Text('确定要清除所有语音缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _audioPlayer.stop();
                await _ttsApi.clearCache();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('缓存已清除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('清除缓存失败：$e')),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
