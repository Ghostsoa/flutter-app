import 'package:flutter/material.dart';

class TipCard extends StatelessWidget {
  static const Color starBlue = Color(0xFF6B8CFF);
  static const Color dreamPurple = Color(0xFFB277FF);
  static const Color lightText = Color(0xFFF0F0F0);

  const TipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            starBlue.withOpacity(0.1),
            dreamPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: starBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: starBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      starBlue.withOpacity(0.2),
                      dreamPurple.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tips_and_updates,
                  color: lightText.withOpacity(0.8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [starBlue, dreamPurple],
                  ).createShader(bounds);
                },
                child: const Text(
                  '功能测试中',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      starBlue.withOpacity(0.2),
                      dreamPurple.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'BETA',
                  style: TextStyle(
                    color: lightText.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            '本功能尚在测试阶段，如遇问题请重试',
            '多次重试无效可尝试清理记录',
            '如果回复文本，请撤销重新生成',
            '如需按特定风格生成图片，建议提供参考图片',
            '禁止生成色情、暴力、幼童等违规内容'
          ]
              .map((text) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [starBlue, dreamPurple],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: lightText.withOpacity(0.6),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
