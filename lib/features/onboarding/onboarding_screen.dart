import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/time/time_engine.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';

/// Aha-first onboarding. The very first thing a new user sees is their own
/// money turned into life-hours, live, as they type — not passive marketing
/// slides. Two short steps, then it saves the profile directly and the auth
/// gate swaps to the home shell.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // Step 1 — money in.
  IncomeType _type = IncomeType.fixed;
  final _income = TextEditingController();
  final _rate = TextEditingController();
  double _daysPerWeek = 5;
  double _hoursPerDay = 8;

  // Step 2 — about you.
  final _name = TextEditingController();
  final _age = TextEditingController();
  Persona _persona = Persona.employee;
  int _workDayStartHour = 0;
  bool _overtimePaid = true;

  // A relatable everyday amount used for the live "aha" example.
  static const double _exampleAmount = 500;

  static const _incomeLabels = {
    IncomeType.fixed: 'Salary',
    IncomeType.hourly: 'Hourly',
    IncomeType.variable: 'Variable',
    IncomeType.allowance: 'Pocket money',
  };

  static const Map<Persona, (IconData, String)> _personaLabels = {
    Persona.student: (Icons.school_outlined, 'Student'),
    Persona.freelancer: (Icons.laptop_mac, 'Freelancer'),
    Persona.employee: (Icons.work_outline, 'Employee'),
    Persona.owner: (Icons.rocket_launch_outlined, 'Owner'),
  };

  @override
  void dispose() {
    _controller.dispose();
    _income.dispose();
    _rate.dispose();
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  bool get _isAllowance => _type == IncomeType.allowance;
  double get _monthly => double.tryParse(_income.text) ?? 0;

  double get _effectiveRate {
    if (_isAllowance) return 0;
    if (_type == IncomeType.hourly) return double.tryParse(_rate.text) ?? 0;
    return TimeEngine.rateFromMonthly(
      netMonthlyIncome: _monthly,
      workDaysPerWeek: _daysPerWeek,
      hoursPerDay: _hoursPerDay,
    );
  }

  double get _monthlyMoney {
    if (_type == IncomeType.hourly) {
      return (double.tryParse(_rate.text) ?? 0) *
          _hoursPerDay *
          _daysPerWeek *
          4.33;
    }
    return _monthly;
  }

  /// Step 1 is satisfied once we can show a real number.
  bool get _step1Valid => _isAllowance ? _monthly > 0 : _effectiveRate > 0;

  void _next() {
    if (_page == 0) {
      FocusScope.of(context).unfocus();
      _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    final profile = const UserProfile().copyWith(
      name: _name.text.trim(),
      age: int.tryParse(_age.text) ?? 0,
      persona: _persona,
      incomeType: _type,
      monthlyIncome: _monthly,
      hourlyRate: double.tryParse(_rate.text) ?? 0,
      workDaysPerWeek: _daysPerWeek,
      hoursPerDay: _hoursPerDay,
      workDayStartHour: _workDayStartHour,
      overtimePaid: _overtimePaid,
      onboarded: true,
    );
    ref.read(appActionsProvider).saveProfile(profile);
    // Profile stream emits onboarded:true → AuthGate swaps to HomeShell.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              _ProgressDots(page: _page, count: 2),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildIncomeStep(context),
                    _buildAboutStep(context),
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

  // ----- Step 1: the aha -----
  Widget _buildIncomeStep(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      children: [
        Text("What's your time worth?", style: t.displayLarge),
        const SizedBox(height: 8),
        Text(
          'TimeWallet turns money into the hours of life it really costs you.',
          style: t.bodyLarge
              ?.copyWith(color: AppColors.muted(context), height: 1.4),
        ),
        const SizedBox(height: 24),
        Text('Where does your money come from?', style: t.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: IncomeType.values.map((it) {
            return ChoiceChip(
              label: Text(_incomeLabels[it]!),
              selected: it == _type,
              onSelected: (_) => setState(() => _type = it),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (_type == IncomeType.hourly)
          _moneyField(_rate, 'Your hourly rate (₹)')
        else
          _moneyField(
            _income,
            _isAllowance
                ? 'Monthly pocket money (₹)'
                : _type == IncomeType.variable
                    ? 'Average monthly income (₹)'
                    : 'Monthly income (₹)',
          ),
        const SizedBox(height: 8),
        // Income is sensitive — say up front that it stays private. Anxiety
        // here is a real drop-off point for first-time users.
        Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.muted(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Private to your account. Never shared, never shown to anyone.',
                style: t.bodySmall?.copyWith(color: AppColors.muted(context)),
              ),
            ),
          ],
        ),
        if (!_isAllowance) ...[
          const SizedBox(height: 12),
          _miniSlider('Work days / week', _daysPerWeek, 1, 7, 6,
              (v) => setState(() => _daysPerWeek = v)),
          _miniSlider('Hours / day', _hoursPerDay, 1, 16, 15,
              (v) => setState(() => _hoursPerDay = v)),
        ],
        const SizedBox(height: 20),
        _AhaCard(
          isAllowance: _isAllowance,
          ready: _step1Valid,
          rate: _effectiveRate,
          monthlyMoney: _monthlyMoney,
          exampleAmount: _exampleAmount,
          hoursPerDay: _hoursPerDay,
        ),
      ],
    );
  }

  // ----- Step 2: about you -----
  Widget _buildAboutStep(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      children: [
        Text('A little about you', style: t.displayLarge),
        const SizedBox(height: 8),
        Text('Helps us tailor what you see. All optional except your role.',
            style: t.bodyLarge?.copyWith(color: AppColors.muted(context))),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name (optional)',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: const InputDecoration(
            labelText: 'Your age (optional)',
            prefixIcon: Icon(Icons.cake_outlined),
          ),
        ),
        const SizedBox(height: 24),
        Text('Which fits you best?', style: t.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: Persona.values.map((p) {
            final (icon, label) = _personaLabels[p]!;
            return ChoiceChip(
              avatar: Icon(icon, size: 18),
              label: Text(label),
              selected: p == _persona,
              onSelected: (_) => setState(() => _persona = p),
            );
          }).toList(),
        ),
        if (!_isAllowance) ...[
          const SizedBox(height: 24),
          Text('Your shift', style: t.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Day shift'),
                selected: _workDayStartHour == 0,
                onSelected: (_) => setState(() => _workDayStartHour = 0),
              ),
              ChoiceChip(
                label: const Text('Night shift'),
                selected: _workDayStartHour != 0,
                onSelected: (_) => setState(() => _workDayStartHour = 12),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Overtime is paid'),
            subtitle: const Text('Earn for hours beyond your daily target'),
            value: _overtimePaid,
            onChanged: (v) => setState(() => _overtimePaid = v),
          ),
        ],
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          if (_page == 1)
            TextButton(
              onPressed: () => _controller.previousPage(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut),
              child: const Text('Back'),
            ),
          const Spacer(),
          FilledButton(
            // The global theme makes FilledButton full-width (infinite min
            // width); inside this Row that throws "infinite width", so cap it.
            style: FilledButton.styleFrom(minimumSize: const Size(140, 50)),
            onPressed: (_page == 0 && !_step1Valid) ? null : _next,
            child: Text(_page == 0 ? 'Continue' : 'Start using TimeWallet'),
          ),
        ],
      ),
    );
  }

  Widget _moneyField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label, prefixText: '₹ '),
      );

  Widget _miniSlider(String label, double value, double min, double max,
      int divisions, ValueChanged<double> onChanged) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
            width: 120, child: Text(label, style: t.bodyMedium)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(value.toStringAsFixed(0),
              textAlign: TextAlign.end, style: t.bodyLarge),
        ),
      ],
    );
  }
}

/// The live "aha" card — the whole pitch in one number.
class _AhaCard extends StatelessWidget {
  final bool isAllowance;
  final bool ready;
  final double rate;
  final double monthlyMoney;
  final double exampleAmount;
  final double hoursPerDay;

  const _AhaCard({
    required this.isAllowance,
    required this.ready,
    required this.rate,
    required this.monthlyMoney,
    required this.exampleAmount,
    required this.hoursPerDay,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    if (!ready) {
      return GradientCard(
        colors: AppColors.auroraMoney,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR AHA MOMENT',
                style: t.labelSmall?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Enter your income to see it',
                style: t.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text("We'll show what ${fmt.format(exampleAmount)} really costs you.",
                style: t.bodyMedium?.copyWith(color: Colors.white70)),
          ],
        ),
      );
    }

    if (isAllowance) {
      final pct = monthlyMoney > 0
          ? (exampleAmount / monthlyMoney * 100).clamp(0, 100)
          : 0;
      return GradientCard(
        colors: AppColors.auroraGreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fmt.format(exampleAmount)} IS',
                style: t.labelSmall?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('${pct.toStringAsFixed(0)}% of your month',
                style: t.displayLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
                'of your ${fmt.format(monthlyMoney)} monthly money. '
                "We'll track spending against this budget.",
                style: t.bodyMedium?.copyWith(color: Colors.white70)),
          ],
        ),
      );
    }

    final minutes = rate > 0 ? (exampleAmount / rate) * 60 : 0.0;
    final timeStr = TimeFormat.longForm(minutes, hoursPerDay: hoursPerDay);
    return GradientCard(
      colors: AppColors.auroraMoney,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${fmt.format(exampleAmount)} REALLY COSTS YOU',
              style: t.labelSmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(timeStr, style: t.displayLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('of your working life — you earn ${fmt.format(rate)}/hour.',
              style: t.bodyMedium?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int page;
  final int count;
  const _ProgressDots({required this.page, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == page;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.money : AppColors.border(context),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
