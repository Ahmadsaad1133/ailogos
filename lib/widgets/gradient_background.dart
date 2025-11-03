import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../themes/colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    this.child,
    this.asset,
    this.padding,
  });

  final Widget? child;
  final String? asset;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.neonBackgroundGradient(accentColor: accent),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset != null)
            SvgPicture.asset(
              asset!,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.06),
                BlendMode.srcATop,
              ),
            ),
          if (child != null)
            Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: child,
            ),
        ],
      ),
    );
  }
}