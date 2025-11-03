import 'package:flutter/material.dart';

class AnimatedGlowButton extends StatefulWidget {
  const AnimatedGlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isBusy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isBusy;

  @override
  State<AnimatedGlowButton> createState() => _AnimatedGlowButtonState();
}

class _AnimatedGlowButtonState extends State<AnimatedGlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = 0.3 + (_controller.value * 0.3);
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(glow),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: widget.isBusy ? null : widget.onPressed,
            icon: widget.isBusy
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
                : Icon(widget.icon),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(widget.isBusy ? 'Generating…' : widget.label),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        );
      },
    );
  }
}