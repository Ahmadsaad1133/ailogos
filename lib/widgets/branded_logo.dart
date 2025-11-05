import 'package:flutter/material.dart';

enum LogoVariant {
  icon,
  watermark,
}

class BrandedLogo extends StatelessWidget {
  const BrandedLogo({
    super.key,
    this.size = 40,
    this.variant = LogoVariant.icon,
  });

  final double size;
  final LogoVariant variant;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      variant == LogoVariant.icon ? size / 4 : size / 6,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        'lib/assets/logos/Obsdiv.jpg', // ✅ matches pubspec
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
