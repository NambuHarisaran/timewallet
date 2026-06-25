import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_body.dart';
import '../salary/salary_setup_screen.dart';

class _Slide {
  final IconData icon;
  final String title, body;
  const _Slide(this.icon, this.title, this.body);
}

const _slides = [
  _Slide(Icons.hourglass_bottom, 'Money is time',
      'Every rupee you spend is a slice of your life. TimeWallet shows the real cost.'),
  _Slide(Icons.local_cafe_outlined, 'See it instantly',
      'That coffee? 18 minutes of work. That phone? 17 days. Decide with clarity.'),
  _Slide(Icons.flag_outlined, 'Buy back your life',
      'Skip impulse buys, hit goals, and watch the hours you reclaim add up.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SalarySetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(s.icon, size: 72, color: AppColors.money),
                        const SizedBox(height: 32),
                        Text(s.title, style: t.displayLarge),
                        const SizedBox(height: 16),
                        Text(s.body,
                            style: t.bodyLarge?.copyWith(
                                color: AppColors.darkMuted, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.money : AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _next,
                child: Text(_page == _slides.length - 1 ? 'Get started' : 'Next'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
