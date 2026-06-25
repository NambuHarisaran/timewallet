import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';

class SalarySetupScreen extends ConsumerStatefulWidget {
  const SalarySetupScreen({super.key});

  @override
  ConsumerState<SalarySetupScreen> createState() => _SalarySetupScreenState();
}

class _SalarySetupScreenState extends ConsumerState<SalarySetupScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  Persona _persona = Persona.employee;
  IncomeType _type = IncomeType.fixed;
  final _income = TextEditingController();
  final _rate = TextEditingController();
  double _daysPerWeek = 5;
  double _hoursPerDay = 8;
  int _workDayStartHour = 0;

  static const Map<Persona, (IconData, String)> _personaLabels = {
    Persona.student: (Icons.school_outlined, 'Student'),
    Persona.freelancer: (Icons.laptop_mac, 'Freelancer'),
    Persona.employee: (Icons.work_outline, 'Employee'),
    Persona.owner: (Icons.rocket_launch_outlined, 'Owner'),
  };

  static const _incomeLabels = {
    IncomeType.fixed: 'Fixed salary',
    IncomeType.hourly: 'Hourly',
    IncomeType.variable: 'Variable',
    IncomeType.allowance: 'Pocket money',
  };

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _income.dispose();
    _rate.dispose();
    super.dispose();
  }

  bool get _isAllowance => _type == IncomeType.allowance;

  double get _effectiveRate {
    if (_isAllowance) return 0;
    if (_type == IncomeType.hourly) return double.tryParse(_rate.text) ?? 0;
    final monthly = double.tryParse(_income.text) ?? 0;
    final hours = _daysPerWeek * 4.33 * _hoursPerDay;
    return hours <= 0 ? 0 : monthly / hours;
  }

  double get _monthly => double.tryParse(_income.text) ?? 0;

  bool get _valid => _isAllowance ? _monthly > 0 : _effectiveRate > 0;

  void _save() {
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
      onboarded: true,
    );
    ref.read(appActionsProvider).saveProfile(profile);
    // First run: profile stream emits onboarded:true -> AuthGate swaps to
    // HomeShell. Re-setup (pushed from Profile): just pop back.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          Text('About you', style: t.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
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
              labelText: 'Your age',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
          ),
          const SizedBox(height: 24),
          Text('Who are you?', style: t.titleLarge),
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
          const SizedBox(height: 24),
          Text('Where does your money come from?', style: t.titleLarge),
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
          if (!_isAllowance) ...[
            const SizedBox(height: 20),
            _slider('Work days / week', _daysPerWeek, 1, 7, 6,
                (v) => setState(() => _daysPerWeek = v)),
            _slider('Hours / day', _hoursPerDay, 1, 16, 15,
                (v) => setState(() => _hoursPerDay = v)),
            const SizedBox(height: 8),
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
          ],
          const SizedBox(height: 16),
          GradientCard(
            colors: _isAllowance
                ? AppColors.auroraGreen
                : AppColors.auroraMoney,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isAllowance ? 'YOUR MONTHLY BUDGET' : 'YOUR TIME IS WORTH',
                    style: t.labelSmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  _isAllowance
                      ? '${fmt.format(_monthly)} / month'
                      : '${fmt.format(_effectiveRate)} / hour',
                  style: t.displayLarge?.copyWith(color: Colors.white),
                ),
                if (_isAllowance) ...[
                  const SizedBox(height: 6),
                  Text("We'll track spending against this budget instead of work-time.",
                      style: t.bodyMedium?.copyWith(color: Colors.white70)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _valid ? _save : null,
            child: const Text('Continue'),
          ),
          ],
        ),
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

  Widget _slider(String label, double value, double min, double max,
      int divisions, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
