import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';

/// "What's it worth?" — a short guided quiz that weighs a purchase and gives a
/// verdict (Worth it / Sleep on it / Skip it) plus its work-time cost. Replaces
/// the old slider-only money→time check on the dashboard.
class WorthQuizScreen extends ConsumerStatefulWidget {
  const WorthQuizScreen({super.key});
  @override
  ConsumerState<WorthQuizScreen> createState() => _WorthQuizState();
}

/// A single quiz question: a prompt and a set of scored options.
class _Q {
  final String key;
  final String prompt;
  final List<_Opt> options;
  const _Q(this.key, this.prompt, this.options);
}

class _Opt {
  final String label;
  final int score; // positive = leans buy, negative = leans skip
  const _Opt(this.label, this.score);
}

const _questions = <_Q>[
  _Q('use', 'How often will you actually use it?', [
    _Opt('Daily', 2),
    _Opt('Weekly', 1),
    _Opt('Rarely', -1),
    _Opt('Once', -2),
  ]),
  _Q('kind', 'Is it a need or a want?', [
    _Opt('Need', 2),
    _Opt('Nice-to-have', 0),
    _Opt('Pure want', -1),
  ]),
  _Q('afford', 'Can you afford it without borrowing?', [
    _Opt('Easily', 2),
    _Opt('A bit tight', 0),
    _Opt('Not really', -2),
  ]),
  _Q('owns', 'Do you already own something similar?', [
    _Opt('No', 1),
    _Opt('Sort of', -1),
    _Opt('Yes', -2),
  ]),
  _Q('wanted', 'How long have you wanted it?', [
    _Opt('Weeks+', 1),
    _Opt('A few days', 0),
    _Opt('Saw it just now', -1),
  ]),
];

class _Verdict {
  final String title;
  final String body;
  final Color color;
  final IconData icon;
  const _Verdict(this.title, this.body, this.color, this.icon);
}

class _WorthQuizState extends ConsumerState<WorthQuizScreen> {
  final _amount = TextEditingController();
  String _categoryId = 'fun';
  final Map<String, int> _answers = {}; // question key -> chosen score

  @override
  void initState() {
    super.initState();
    // Reuse the onboarding completion signal so the Start-here step ticks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(triedWorthItProvider.notifier).setCompleted();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;
  bool get _allAnswered => _answers.length == _questions.length;

  int get _total => _answers.values.fold(0, (a, b) => a + b);

  _Verdict _verdictFor(int score) {
    if (score >= 3) {
      return const _Verdict('Worth it', 'The answers point to real, lasting value. Go ahead.',
          AppColors.positive, Icons.thumb_up_alt_outlined);
    }
    if (score <= -2) {
      return const _Verdict('Skip it', 'This looks like a low-value or impulse buy. Reclaim the time instead.',
          AppColors.warn, Icons.do_not_disturb_alt_outlined);
    }
    return const _Verdict('Sleep on it', 'It is borderline. Put it on hold for 24h and decide with a clear head.',
        AppColors.time, Icons.bedtime_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);
    final ready = _value > 0 && _allAnswered;

    return Scaffold(
      appBar: AppBar(title: const Text("What's it worth?")),
      bottomNavigationBar: ready
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54)),
                        onPressed: _buy,
                        child: const Text('Buy it'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.positive,
                            minimumSize: const Size.fromHeight(54)),
                        onPressed: _skip,
                        child: const Text('Skip & reclaim'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Price', style: t.labelSmall),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: t.displayLarge?.copyWith(fontSize: 40),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                filled: false,
                border: InputBorder.none,
                hintText: '0',
              ),
            ),
            if (_value > 0)
              Text(
                profile.tracksTime
                    ? '= ${TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)} of your life'
                    : '= ₹${_value.toStringAsFixed(0)}',
                style: t.bodyLarge?.copyWith(color: AppColors.time),
              ),
            const SizedBox(height: 20),
            for (final q in _questions) _question(q, t),
            const SizedBox(height: 20),
            Text('Category', style: t.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.all.map((c) {
                return ChoiceChip(
                  avatar: Icon(c.icon, size: 18),
                  label: Text(c.label),
                  selected: c.id == _categoryId,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (ready) _verdictCard(t) else _hint(t),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _question(_Q q, TextTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.prompt, style: t.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: q.options.map((o) {
              final selected = _answers[q.key] == o.score &&
                  _answers.containsKey(q.key);
              return ChoiceChip(
                label: Text(o.label),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _answers[q.key] = o.score),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _hint(TextTheme t) {
    final left = _questions.length - _answers.length;
    return Center(
      child: Text(
        _value <= 0
            ? 'Enter a price and answer the questions for a verdict.'
            : 'Answer $left more to see the verdict.',
        style: t.bodyMedium?.copyWith(color: AppColors.darkMuted),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _verdictCard(TextTheme t) {
    final v = _verdictFor(_total);
    return GradientCard(
      colors: [v.color.withValues(alpha: 0.85), v.color.withValues(alpha: 0.55)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(v.icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(v.title,
                  style: t.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(v.body, style: t.bodyMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  NeedWant get _needWant =>
      (_answers['kind'] ?? 0) >= 2 ? NeedWant.need : NeedWant.want;

  void _buy() {
    final profile = ref.read(profileOrDefaultProvider);
    ref.read(appActionsProvider).addExpense(
          amount: _value,
          categoryId: _categoryId,
          mood: Mood.neutral,
          needWant: _needWant,
          timeCostMinutes: profile.engine.minutesFor(_value),
        );
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  void _skip() {
    final profile = ref.read(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);
    ref.read(appActionsProvider).skipPurchase(
        minutes: minutes,
        categoryLabel: ExpenseCategory.byId(_categoryId).label);
    HapticFeedback.mediumImpact();
    final msg = profile.tracksTime && minutes > 0
        ? 'Reclaimed ${TimeFormat.hm(minutes, hoursPerDay: profile.hoursPerDay)}'
        : 'Smart skip';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    Navigator.of(context).pop();
  }
}
