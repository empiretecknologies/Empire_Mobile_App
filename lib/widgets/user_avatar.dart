import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../session/app_session.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.radius = 22,
    this.backgroundColor = AppColors.forest,
    this.foregroundColor = AppColors.onForest,
  });

  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final name = AppSession.instance.username?.trim() ?? '';
    final letter = name.isEmpty ? 'U' : name[0].toUpperCase();

    return ValueListenableBuilder<Uint8List?>(
      valueListenable: AppSession.instance.profileImage,
      builder: (context, bytes, _) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          foregroundImage: bytes == null ? null : MemoryImage(bytes),
          child: Text(
            letter,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.72,
            ),
          ),
        );
      },
    );
  }
}
