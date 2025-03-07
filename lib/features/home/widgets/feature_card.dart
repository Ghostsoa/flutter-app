import 'package:flutter/material.dart';

class FeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool showInfo;
  final String? infoText;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.showInfo = false,
    this.infoText,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.1, end: -0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.1, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25.0,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25.0,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: widget.color),
            const SizedBox(width: 8),
            const Text('抽奖说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            widget.infoText ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  void _handleTap() {
    if (!widget.isLoading && widget.onTap != null) {
      _controller.forward(from: 0).then((_) {
        widget.onTap?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..rotateZ(_rotationAnimation.value)
                ..scale(_scaleAnimation.value),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color,
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '消耗10小懿币',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showInfo)
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        onPressed: () => _showInfoDialog(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (widget.isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
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
