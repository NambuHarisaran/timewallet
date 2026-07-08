import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/time/time_engine.dart';
import '../../core/util/formatters.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/step_progress_bar.dart';
import '../../widgets/time_card.dart';

/// Aha-first onboarding. The very first thing a new user sees is their own
/// money turned into life-hours, live, as they type — not passive marketing
/// slides. Three short steps — income, about you, design your Time Card —
/// prefilled from the pre-signup intro where possible (smart defaults), then
/// it saves the profile directly and the auth gate swaps to the home shell.
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

  // Step 3 — the user's own Time Card (IKEA effect).
  int _cardStyle = 0;
  bool _cardCelebrated = false;

  // True when the income box was seeded from the pre-signup intro — we say
  // so in the UI, because silent prefills read as spooky, named ones as smart.
  bool _incomePrefilled = false;

  // A relatable everyday amount used for the live "aha" example.
  static const double _exampleAmount = 500;

  // Endowed progress: creating the account already "earned" the first 25%,
  // so the bar never starts at zero (goal-gradient effect).
  static const _stepProgress = [0.25, 0.5, 0.75];

  @override
  void initState() {
    super.initState();
    // Smart defaults — reuse what the intro flow already learned so the
    // form arrives mostly answered (decision-fatigue relief).
    final prefs = ref.read(sharedPrefsProvider);
    final introIncome = prefs.getDouble(IntroSeenNotifier.incomeKey);
    if (introIncome != null && introIncome > 0) {
      _income.text = introIncome.toStringAsFixed(0);
      _incomePrefilled = true;
    }
    final personaIdx = prefs.getInt(IntroSeenNotifier.personaKey);
    if (personaIdx != null &&
        personaIdx >= 0 &&
        personaIdx < Persona.values.length) {
      _persona = Persona.values[personaIdx];
      // Infer the likely income source from who they are — freely changeable.
      _type = switch (_persona) {
        Persona.student => IncomeType.allowance,
        Persona.employee => IncomeType.fixed,
        Persona.freelancer || Persona.owner => IncomeType.variable,
      };
    }
    // Google accounts arrive with a display name — don't make them retype
    // it. Best-effort: platforms/tests without Firebase simply skip this.
    try {
      final displayName =
          ref.read(firebaseAuthProvider).currentUser?.displayName?.trim();
      if (displayName != null && displayName.isNotEmpty) {
        _name.text = displayName;
      }
    } catch (_) {}
  }

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
    if (_page < 2) {
      FocusScope.of(context).unfocus();
      _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  /// The profile as designed so far — feeds the live Time Card preview and
  /// (with onboarded:true) the final save, so preview and truth can't drift.
  UserProfile get _draftProfile => const UserProfile().copyWith(
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
        cardStyle: _cardStyle,
      );

  void _finish() {
    final profile = _draftProfile.copyWith(onboarded: true);
    final analytics = ref.read(analyticsServiceProvider);
    analytics.onboardingComplete(
        incomeType: _type.name, tracksTime: profile.tracksTime);
    analytics.cardDesigned(style: _cardStyle);
    // Capture the messenger before the async gap — context may be gone by the
    // time a failure returns. On success the profile stream emits
    // onboarded:true and AuthGate swaps to HomeShell; on failure (e.g. an
    // unverified account) surface it instead of crashing on an unhandled
    // rejection and leaving the user stuck on this screen.
    final messenger = ScaffoldMessenger.of(context);
    ref.read(appActionsProvider).saveProfile(profile).catchError((_) {
      messenger.showSnackBar(const SnackBar(
        content: Text(
            "Couldn't save your profile. Check your connection (and that "
            'your email is verified), then try again.'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepProgressBar(
                      value: _stepProgress[_page],
                      label: 'Step ${_page + 1} of 3',
                    ),
                    if (_page == 0) ...[
                      const SizedBox(height: 10),
                      // Why the bar starts at 25%: signing up counts. Naming
                      // it makes the head start feel earned, not fake.
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.positive),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Account created — you\'re already 25% done',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.muted(context)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    // Reaching the card step is the reward moment — the
                    // profile work is done, now they get to build something.
                    if (i == 2 && !_cardCelebrated) {
                      _cardCelebrated = true;
                      celebrate(context);
                    }
                  },
                  children: [
                    _buildIncomeStep(context),
                    _buildAboutStep(context),
                    _buildCardStep(context),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Text("What's your time worth?",
            style: t.displayLarge?.copyWith(height: 1.05)),
        const SizedBox(height: 12),
        Text(
          'TimeWallet turns money into the hours of life it really costs you.',
          style: t.bodyLarge
              ?.copyWith(color: AppColors.muted(context), height: 1.45),
        ),
        const SizedBox(height: 28),
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
        if (_incomePrefilled && _type != IncomeType.hourly) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Prefilled from your earlier answer — tweak anytime.',
                  style: t.bodySmall
                      ?.copyWith(color: AppColors.muted(context)),
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Text('A little about you',
            style: t.displayLarge?.copyWith(height: 1.05)),
        const SizedBox(height: 12),
        Text('Helps us tailor what you see. All optional except your role.',
            style: t.bodyLarge
                ?.copyWith(color: AppColors.muted(context), height: 1.45)),
        const SizedBox(height: 28),
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
          const SizedBox(height: 16),
          // Shift + overtime hide behind one collapsed row: the defaults
          // (day shift, paid overtime) fit most people, so the step stays a
          // single real decision — persona (decision-fatigue relief).
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text('Fine-tune (optional)', style: t.titleMedium),
            subtitle: Text(
              'Shift and overtime — defaults fit most people',
              style: t.bodySmall?.copyWith(color: AppColors.muted(context)),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Day shift'),
                      selected: _workDayStartHour == 0,
                      onSelected: (_) =>
                          setState(() => _workDayStartHour = 0),
                    ),
                    ChoiceChip(
                      label: const Text('Night shift'),
                      selected: _workDayStartHour != 0,
                      onSelected: (_) =>
                          setState(() => _workDayStartHour = 12),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Overtime is paid'),
                subtitle:
                    const Text('Earn for hours beyond your daily target'),
                value: _overtimePaid,
                onChanged: (v) => setState(() => _overtimePaid = v),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ----- Step 3: design your Time Card (IKEA effect) -----
  Widget _buildCardStep(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Text('Design your Time Card',
            style: t.displayLarge?.copyWith(height: 1.05)),
        const SizedBox(height: 12),
        Text(
          'Pick a style. This card is yours — it lives at the top of your '
          'profile.',
          style: t.bodyLarge
              ?.copyWith(color: AppColors.muted(context), height: 1.45),
        ),
        const SizedBox(height: 28),
        TimeCard(profile: _draftProfile),
        const SizedBox(height: 24),
        TimeCardStylePicker(
          selected: _cardStyle,
          onSelected: (i) => setState(() => _cardStyle = i),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.brush_outlined, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'You built this. Change the style anytime from Edit profile.',
                style:
                    t.bodySmall?.copyWith(color: AppColors.muted(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          if (_page > 0) ...[
            TextButton(
              onPressed: () => _controller.previousPage(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
          ],
          // Expanded so the CTA fills the row width — the long final label
          // ("Start using TimeWallet") then renders at full size. FittedBox
          // stays only as a guard for extreme accessibility text scales.
          Expanded(
            child: FilledButton(
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              onPressed: (_page == 0 && !_step1Valid) ? null : _next,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                    _page == 2 ? 'Start using TimeWallet' : 'Continue'),
              ),
            ),
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
    final fmt = moneyFmt;

    if (!ready) {
      return GradientCard(
        colors: AppColors.heroNeutral,
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
        colors: AppColors.heroPositive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fmt.format(exampleAmount)} IS',
                style: t.labelSmall?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${pct.toStringAsFixed(0)}% of your month',
                  maxLines: 1,
                  style: t.displayLarge?.copyWith(color: Colors.white)),
            ),
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
      colors: AppColors.heroNeutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${fmt.format(exampleAmount)} REALLY COSTS YOU',
              style: t.labelSmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(timeStr,
                maxLines: 1,
                style: t.displayLarge?.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text('of your working life — you earn ${fmt.format(rate)}/hour.',
              style: t.bodyMedium?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

