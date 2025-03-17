import 'package:flutter/material.dart';
import 'dart:math' show pi, sin;

class LoadingDots extends StatefulWidget {
  static const Color lightText = Color(0xFFF0F0F0);

  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AI思考中',
          style: TextStyle(
            color: LoadingDots.lightText.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double offset = sin(
                  (_controller.value * 2 * pi) + (index * pi / 2),
                );
                return Transform.translate(
                  offset: Offset(0, -4 * offset),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: LoadingDots.lightText.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
