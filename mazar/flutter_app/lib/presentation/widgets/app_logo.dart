import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// نسخة مصغّرة من شعار مزار تُستخدم في شريط التطبيق وشاشات أخرى
/// غير شاشة البداية، حيث يُستخدم الشعار الكامل المتحرك بدلاً منها.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Icon(Icons.nights_stay_rounded, color: AppColors.gold, size: size * 0.55),
    );
  }
}
