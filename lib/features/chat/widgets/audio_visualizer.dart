import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';

class AudioVisualizer extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final Color color;
  final double height;
  final int barCount;

  const AudioVisualizer({
    super.key,
    required this.audioPlayer,
    required this.color,
    this.height = 20,
    this.barCount = 27,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _barHeights = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // 初始化条形高度
    _barHeights.addAll(
      List.generate(widget.barCount, (index) => 0.2),
    );

    // 监听播放状态
    widget.audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    });
  }

  void _startAnimation() {
    _animationController.repeat();
    _animationController.addListener(_updateBars);
  }

  void _stopAnimation() {
    _animationController.stop();
    setState(() {
      for (var i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = 0.2;
      }
    });
  }

  void _updateBars() {
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _barHeights.length; i++) {
        // 生成随机高度，但保持平滑过渡
        final targetHeight = 0.2 + _random.nextDouble() * 0.8;
        _barHeights[i] = _barHeights[i] * 0.8 + targetHeight * 0.2;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          widget.barCount,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              height: widget.height * _barHeights[index],
              width: 2,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
