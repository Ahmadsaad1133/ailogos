import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandedLogo extends StatelessWidget {
  const BrandedLogo({super.key, this.size = 160, this.variant = LogoVariant.primary});

  final double size;
  final LogoVariant variant;

  String get _assetPath {
    switch (variant) {
      case LogoVariant.primary:
        return 'lib/assets/logos/logo_primary.svg';
      case LogoVariant.icon:
        return 'lib/assets/logos/logo_icon.svg';
      case LogoVariant.watermark:
        return 'lib/assets/logos/logo_watermark.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

enum LogoVariant { primary, icon, watermark }