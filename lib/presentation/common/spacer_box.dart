import 'package:flutter/material.dart';

enum SpacerBoxType { vertical, horizontal }

enum SpacerBoxSize { small, medium, large }

class SpacerBox extends StatelessWidget {
  const SpacerBox({required this.type, required this.size, super.key});

  final SpacerBoxType type;
  final SpacerBoxSize size;

  // Spacing is calculated as the multiple of 2
  @override
  Widget build(BuildContext context) {
    return switch (size) {
      SpacerBoxSize.small when (type == SpacerBoxType.vertical) =>
        const SizedBox(height: 6),
      SpacerBoxSize.medium when (type == SpacerBoxType.vertical) =>
        const SizedBox(height: 12),
      SpacerBoxSize.large when (type == SpacerBoxType.vertical) =>
        const SizedBox(height: 24),
      SpacerBoxSize.small => const SizedBox(width: 4),
      SpacerBoxSize.medium => const SizedBox(width: 8),
      SpacerBoxSize.large => const SizedBox(width: 16),
    };
  }
}
