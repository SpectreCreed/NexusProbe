import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.radar_rounded,
      title: 'Email Intelligence',
      subtitle:
          'Investigate any email address with comprehensive OSINT — breaches, social footprint, domain intel & more.',
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      title: 'Breach Detection',
      subtitle:
          'Instantly check if an email was exposed in known data breaches using Have I Been Pwned integration.',
    ),
    _OnboardingPage(
      icon: Icons.account_tree_rounded,
      title: 'Social Footprint',
      subtitle:
          'Discover registered accounts across 100+ platforms using Holehe and other OSINT tools.',
    ),
    _OnboardingPage(
      icon: Icons.gavel_rounded,
      title: 'Use Responsibly',
      isDisclaimer: true,
      title2: '⚠️ Responsible Use Required',
      subtitle:
          'This tool is for legitimate security research, journalism, and privacy awareness only.\n\n'
          'You must comply with all applicable laws. Do not use this tool to:\n'
          '• Stalk or harass individuals\n'
          '• Violate privacy without consent\n'
          '• Break any local or international law\n\n'
          'By continuing, you agree to these terms.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.accent : AppTheme.surfaceBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finish();
                        }
                      },
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Next' : 'I Agree & Continue',
                      ),
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

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? title2;
  final String subtitle;
  final bool isDisclaimer;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.title2,
    this.isDisclaimer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: isDisclaimer
                  ? const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFDC2626)],
                    )
                  : AppTheme.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: (isDisclaimer ? AppTheme.warning : AppTheme.accent)
                      .withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 60),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fade(duration: 400.ms),

          const SizedBox(height: 40),

          Text(
            title2 ?? title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDisclaimer ? AppTheme.warning : AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          Text(
            subtitle,
            textAlign: isDisclaimer ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
