import 'package:flutter/material.dart';
import 'dart:io';

class ChatBackground extends StatelessWidget {
  final String? coverImageUrl;
  final double backgroundOpacity;
  final List<Widget> children;

  const ChatBackground({
    super.key,
    this.coverImageUrl,
    required this.backgroundOpacity,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: coverImageUrl != null
            ? DecorationImage(
                image: coverImageUrl!.startsWith('/')
                    ? FileImage(File(coverImageUrl!)) as ImageProvider
                    : NetworkImage(coverImageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(backgroundOpacity),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: children,
      ),
    );
  }
}
