import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../widgets/animated_glow_button.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await context.read<AppState>().markOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_onboarding.svg',
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const BrandedLogo(size: 120, variant: LogoVariant.icon),
            const SizedBox(height: 12),
            Text('Powered by OBSDIV', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: const [
                  _OnboardingPage(
                    asset: 'lib/assets/mockups/mockup_home.svg',
                    title: 'Command the Canvas',
                    description:
                    'Transform futuristic prompts into cinematic artworks with the OBSDIV engine.',
                  ),
                  _OnboardingPage(
                    asset: 'lib/assets/mockups/mockup_history.svg',
                    title: 'Relive Every Vision',
                    description:
                    'Your neon creations are stored in a living timeline with instant previews.',
                  ),
                  _OnboardingPage(
                    asset: 'lib/assets/mockups/mockup_result.svg',
                    title: 'Share the Glow',
                    description:
                    'Export ultra-sharp renders straight to your gallery or share channels.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 18),
                  height: 8,
                  width: _currentPage == index ? 32 : 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: AnimatedGlowButton(
                label: _currentPage < 2 ? 'Next' : 'Launch App',
                icon: Icons.arrow_forward_rounded,
                onPressed: _goNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.asset,
    required this.title,
    required this.description,
  });

  final String asset;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SvgPicture.asset(
                      asset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}