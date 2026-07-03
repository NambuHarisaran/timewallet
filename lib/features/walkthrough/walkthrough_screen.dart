import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/gradient_card.dart';
import '../help/glossary_screen.dart';

class _Step {
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String body;
  const _Step(this.icon, this.colors, this.title, this.body);
}

const _steps = <_Step>[
  _Step(Icons.hourglass_bottom, AppColors.heroNeutral, 'Money is time',
      'Every rupee is shown as the work-time it costs you. ₹500 might be 1 hour of your life.'),
  _Step(Icons.timer_outlined, AppColors.heroNeutral, 'Log your work',
      'Tap "Log work time" on Home as you work. Beyond your daily hours becomes overtime — earned only if your overtime is paid. Night shifts that cross midnight count as one day.'),
  _Step(Icons.payments_outlined, AppColors.heroNeutral, 'Add expenses',
      'Add what you spend and instantly see it in hours, not just rupees. Mark it Need or Want.'),
  _Step(Icons.pause_circle_outline, AppColors.heroNeutral, 'Hold & reclaim',
      'Put a "want" on a 24-hour hold. Skip it and you reclaim that work-time — it adds up.'),
  _Step(Icons.flag_outlined, AppColors.heroPositive, 'Goals in work-days',
      'Set a goal and see how many work-days — and how much overtime per day — it takes to reach it.'),
  _Step(Icons.savings_outlined, AppColors.heroPositive, 'Plan the big decisions',
      'The Plan tab holds seven planning engines (asset allocation, health score, SWP, debt, child-legacy, retirement) plus quick calculators — "Worth it?", SIP, FD, inflation and a financial-freedom countdown.'),
  _Step(Icons.event_repeat_rounded, AppColors.heroNeutral, 'Review your week',
      'Every Sunday your Life Receipt shows the week in hours — earned, spent, and reclaimed. The Review tab also holds your Wrapped recap, insights and achievements.'),
];

/// Swipeable tour of every feature. Shown once after onboarding and replayable
/// from Profile → "How it works".
class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('has_viewed_tour', true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final last = _page == _steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GradientCard(
                          colors: s.colors,
                          padding: const EdgeInsets.all(36),
                          child: Center(
                            child: Icon(s.icon, size: 72, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(s.title, style: t.displayLarge),
                        const SizedBox(height: 12),
                        Text(s.body,
                            style: t.bodyLarge?.copyWith(height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        active ? AppColors.accent : AppColors.border(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: FilledButton(
                onPressed: _next,
                child: Text(last ? "Got it — let's go" : 'Next'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const GlossaryScreen())),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('What the words mean'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
