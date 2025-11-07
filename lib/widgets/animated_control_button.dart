import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A highly expressive control used across the home screen to
/// replace the previous [IconButton]s. It renders a soft depth
/// elevation, reacts to hover and press states, and spawns a
/// particle burst trail that quickly dissipates after tap.
class AnimatedControlButton extends StatefulWidget {
  const AnimatedControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 52,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  @override
  State<AnimatedControlButton> createState() => _AnimatedControlButtonState();
}

class _AnimatedControlButtonState extends State<AnimatedControlButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _hoverController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  final Random _random = Random();
  late List<_ParticleFragment> _fragments;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.92)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 26,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.92, end: 1.04)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 34,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.04, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40,
        ),
      ],
    ).animate(_pressController);

    _glowAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    );

    _fragments = _generateFragments();
  }

  @override
  void dispose() {
    _pressController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _fragments = _generateFragments();
    widget.onPressed();
  }

  List<_ParticleFragment> _generateFragments() {
    return List<_ParticleFragment>.generate(12, (index) {
      final angle = (_random.nextDouble() * pi * 2) - pi;
      final travel = widget.size * (0.5 + _random.nextDouble() * 0.8);
      final delay = _random.nextDouble() * 0.25;
      final radius = 2.0 + _random.nextDouble() * 2.5;
      return _ParticleFragment(
        angle: angle,
        travel: travel,
        radius: radius,
        delay: delay,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = widget.color ?? colorScheme.surfaceVariant.withOpacity(0.35);
    final iconColor = colorScheme.onSurface;

    final button = GestureDetector(
      onTapDown: (_) {
        if (_pressController.status != AnimationStatus.forward) {
          _pressController.forward(from: 0);
        }
      },
      onTapCancel: () => _pressController.reverse(),
      onTapUp: (_) {},
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _hoverController]),
        builder: (context, child) {
          final glowStrength = (_glowAnimation.value * 0.4) + 0.25;
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    surfaceColor.withOpacity(0.9),
                    surfaceColor.withOpacity(0.25),
                  ],
                  center: Alignment.topLeft,
                  radius: 1.2,
                ),
                borderRadius: BorderRadius.circular(widget.size),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.15 * glowStrength),
                    blurRadius: 24 * glowStrength,
                    spreadRadius: 2 * glowStrength,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.18 + glowStrength * 0.2),
                  width: 1.2,
                ),
              ),
              child: SizedBox(
                height: widget.size,
                width: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _ParticlePainter(
                        fragments: _fragments,
                        progress: _pressController.value,
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(
                      widget.icon,
                      color: iconColor,
                      size: widget.size * 0.46,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    final wrapped = MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: button,
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip,
        triggerMode: TooltipTriggerMode.longPress,
        child: wrapped,
      );
    }

    return wrapped;
  }
}

class _ParticleFragment {
  const _ParticleFragment({
    required this.angle,
    required this.travel,
    required this.radius,
    required this.delay,
  });

  final double angle;
  final double travel;
  final double radius;
  final double delay;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.fragments,
    required this.progress,
    required this.color,
  });

  final List<_ParticleFragment> fragments;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint();

    for (final fragment in fragments) {
      final effective = ((progress - fragment.delay).clamp(0, 1)) as double;
      if (effective <= 0) {
        continue;
      }
      final eased = Curves.easeOut.transform(effective);
      final distance = fragment.travel * eased;
      final offset = Offset.fromDirection(fragment.angle, distance);
      final opacity = (1 - effective).clamp(0.0, 1.0);
      paint.color = color.withOpacity(0.35 * opacity + 0.15);
      canvas.drawCircle(center + offset, fragment.radius * (0.8 + eased * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.fragments != fragments ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}