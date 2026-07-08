import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/time/time_engine.dart';
import '../../core/util/formatters.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/step_progress_bar.dart';

/// Pre-signup teaching flow (Duolingo pattern). Before we ask for an email,
/// the user drags their own income, plays one quiz round, and picks who they
/// are — three interactive beats that teach "money is time" AND collect the
/// answers we prefill after signup. By the time the signup wall appears
/// they've invested effort and the app already knows them.
class IntroFlowScreen extends ConsumerStatefulWidget {
  const IntroFlowScreen({super.key});

  @override
  ConsumerState<IntroFlowScreen> createState() => _IntroFlowScreenState();
}

class _IntroFlowScreenState extends ConsumerState<IntroFlowScreen> {
  final _controller = PageController();
  int _page = 0;

  // Page 1 — their income, collected by playing, not by form-filling.
  double _income = 50000;

  // Page 2 — quiz state. Locked after the first tap so the reveal lands.
  int? _quizPick; // 0 = subscription, 1 = gadget
  static const double _subMonthly = 199;
  static const double _gadgetOnce = 1999;

  // Page 3 — persona. No preselect: one deliberate tap is the investment.
  Persona? _persona;

  static const Map<Persona, (IconData, String, String)> _personaOptions = {
    Persona.student: (
      Icons.school_outlined,
      'Student',
      'Pocket money, tight budgets'
    ),
    Persona.freelancer: (
      Icons.laptop_mac,
      'Freelancer',
      'Income changes month to month'
    ),
    Persona.employee: (
      Icons.work_outline,
      'Employee',
      'Fixed monthly salary'
    ),
    Persona.owner: (
      Icons.rocket_launch_outlined,
      'Business owner',
      'You pay yourself'
    ),
  };

  // Endowed progress: the bar never sits at 0 — arriving already counts.
  static const _progress = [0.2, 0.55, 0.85];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _rate => TimeEngine.rateFromMonthly(
        netMonthlyIncome: _income,
        workDaysPerWeek: 5,
        hoursPerDay: 8,
      );

  bool get _canContinue {
    if (_page == 1) return _quizPick != null; // must play the round
    if (_page == 2) return _persona != null; // must pick who they are
    return true;
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    _controller.previousPage(
        duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
  }

  void _finish() {
    final persona = _persona ?? Persona.employee;
    ref.read(analyticsServiceProvider).introComplete(persona: persona.name);
    // Signup is the natural next step for someone who just invested effort.
    ref.read(sharedPrefsProvider).setBool('lastAuthModeSignUp', true);
    ref
        .read(introSeenProvider.notifier)
        .complete(income: _income, persona: persona);
    // introSeenProvider flips → AuthGate swaps to LoginScreen.
  }

  void _skipToLogin() {
    // Returning user — open login (not signup) and never show the intro again.
    ref.read(sharedPrefsProvider).setBool('lastAuthModeSignUp', false);
    ref.read(introSeenProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StepProgressBar(
                        value: _progress[_page],
                        label: 'Step ${_page + 1} of 3',
                      ),
                    ),
                    TextButton(
                      onPressed: _skipToLogin,
                      child: const Text('I have an account'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildMoneyIsTime(context),
                    _buildQuiz(context),
                    _buildPersona(context),
                  ],
                ),
              ),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Page 1: money is time — teach by dragging, collect income -----
  Widget _buildMoneyIsTime(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final minutes = _rate > 0 ? (500 / _rate) * 60 : 0.0;
    final timeStr = TimeFormat.longForm(minutes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        Text('Your money is time.', style: t.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Every rupee you spend was bought with hours of your life. '
          'Drag your monthly income and watch what ₹500 really costs.',
          style: t.bodyLarge
              ?.copyWith(color: AppColors.muted(context), height: 1.4),
        ),
        const SizedBox(height: 24),
        GradientCard(
          colors: AppColors.heroNeutral,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹500 REALLY COSTS YOU',
                  style: t.labelSmall?.copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeStr,
                  maxLines: 1,
                  style: t.displayLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'of working life at ${moneyFmt.format(_income)}/month.',
                style: t.bodyMedium?.copyWith(color: Colors.white70),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.accent,
                  overlayColor: AppColors.accent.withValues(alpha: 0.15),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _income,
                  min: 10000,
                  max: 300000,
                  divisions: 29,
                  onChanged: (v) => setState(() => _income = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nothing to type, nothing saved yet — just drag.',
          style: t.bodySmall?.copyWith(color: AppColors.muted(context)),
        ),
      ],
    );
  }

  // ----- Page 2: one quiz round — invest effort, learn recurring drain -----
  Widget _buildQuiz(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final revealed = _quizPick != null;
    final subMinutes = (_subMonthly * 12 / _rate) * 60;
    final gadgetMinutes = (_gadgetOnce / _rate) * 60;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        Text('Small leaks sink ships.', style: t.displayLarge),
        const SizedBox(height: 8),
        Text(
          'At ${moneyFmt.format(_income)}/month — which steals more of your '
          'working life in a year? Tap your guess.',
          style: t.bodyLarge
              ?.copyWith(color: AppColors.muted(context), height: 1.4),
        ),
        const SizedBox(height: 24),
        _QuizOption(
          icon: Icons.subscriptions_outlined,
          title: '₹199/month subscription',
          subtitle: 'Runs quietly all year',
          revealed: revealed,
          revealText:
              '${TimeFormat.longForm(subMinutes)} of your life per year',
          isAnswer: true, // ₹2,388/yr — the quiet leak wins
          picked: _quizPick == 0,
          onTap: revealed ? null : () => _pickQuiz(0),
        ),
        const SizedBox(height: 12),
        _QuizOption(
          icon: Icons.devices_other,
          title: '₹1,999 gadget',
          subtitle: 'One-time buy',
          revealed: revealed,
          revealText:
              '${TimeFormat.longForm(gadgetMinutes)} of your life, once',
          isAnswer: false,
          picked: _quizPick == 1,
          onTap: revealed ? null : () => _pickQuiz(1),
        ),
        if (revealed) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _quizPick == 0
                    ? Icons.check_circle_outline
                    : Icons.lightbulb_outline,
                size: 20,
                color:
                    _quizPick == 0 ? AppColors.positive : AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _quizPick == 0
                      ? 'Exactly. The quiet ₹199 drains '
                          '${moneyFmt.format(_subMonthly * 12)} a year — more '
                          'than the gadget. TimeWallet keeps these leaks visible.'
                      : 'Sneaky, right? The quiet ₹199 adds up to '
                          '${moneyFmt.format(_subMonthly * 12)} a year — more '
                          'than the gadget. TimeWallet keeps these leaks visible.',
                  style: t.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _pickQuiz(int i) {
    setState(() => _quizPick = i);
    if (i == 0) celebrate(context); // got it right — reward the insight
  }

  // ----- Page 3: who are you — one tap sets every default -----
  Widget _buildPersona(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      children: [
        Text('Who are you?', style: t.displayLarge),
        const SizedBox(height: 8),
        Text(
          'One tap — we preset everything else for you. '
          'You can change anything later.',
          style: t.bodyLarge
              ?.copyWith(color: AppColors.muted(context), height: 1.4),
        ),
        const SizedBox(height: 24),
        ..._personaOptions.entries.map((e) {
          final (icon, label, hint) = e.value;
          final selected = e.key == _persona;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Pressable(
              onTap: () => setState(() => _persona = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? AppColors.accent
                        : AppColors.border(context),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 26,
                        color: selected
                            ? AppColors.accent
                            : AppColors.muted(context)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: t.titleMedium),
                          const SizedBox(height: 2),
                          Text(hint,
                              style: t.bodySmall?.copyWith(
                                  color: AppColors.muted(context))),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AppColors.accent, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          if (_page > 0) ...[
            TextButton(onPressed: _back, child: const Text('Back')),
            const SizedBox(width: 12),
          ],
          // Expanded so the CTA fills the row and its label renders full-size;
          // FittedBox stays only as a guard for extreme text scales.
          Expanded(
            child: FilledButton(
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              onPressed: _canContinue ? _next : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_page == 2 ? 'Create my account' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable quiz answer. Before the reveal it's a guess card; after,
/// it shows its true cost in life-hours and whether it was the bigger leak.
class _QuizOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool revealed;
  final String revealText;
  final bool isAnswer;
  final bool picked;
  final VoidCallback? onTap;

  const _QuizOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.revealed,
    required this.revealText,
    required this.isAnswer,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final borderColor = !revealed
        ? AppColors.border(context)
        : isAnswer
            ? AppColors.positive
            : picked
                ? AppColors.warn
                : AppColors.border(context);

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: revealed ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: AppColors.muted(context)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    revealed ? revealText : subtitle,
                    style: t.bodySmall?.copyWith(
                      color: revealed && isAnswer
                          ? AppColors.positive
                          : AppColors.muted(context),
                      fontWeight: revealed && isAnswer ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            if (revealed && isAnswer)
              const Icon(Icons.trending_up, color: AppColors.positive),
          ],
        ),
      ),
    );
  }
}
