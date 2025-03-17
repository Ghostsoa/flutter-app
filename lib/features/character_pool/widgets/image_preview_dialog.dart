import 'package:flutter/material.dart';
import 'dart:typed_data';

class ImagePreviewDialog extends StatelessWidget {
  final Uint8List imageData;
  final Function(Uint8List) onSave;

  static const Color starBlue = Color(0xFF6B8CFF);
  static const Color dreamPurple = Color(0xFFB277FF);
  static const Color lightText = Color(0xFFF0F0F0);

  const ImagePreviewDialog({
    super.key,
    required this.imageData,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(8),
      child: RepaintBoundary(
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                imageData,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [starBlue, dreamPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: starBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.save,
                        color: lightText,
                        size: 20,
                      ),
                      onPressed: () => onSave(imageData),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [starBlue, dreamPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: starBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: lightText,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
