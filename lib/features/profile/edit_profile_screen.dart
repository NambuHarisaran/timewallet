import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/section_card.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _income;
  late final TextEditingController _rate;
  late Persona _persona;
  late IncomeType _type;
  late double _daysPerWeek;
  late double _hoursPerDay;
  late int _workDayStartHour;
  late bool _overtimePaid;

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
  void initState() {
    super.initState();
    final p = ref.read(profileOrDefaultProvider);
    _name = TextEditingController(text: p.name);
    _age = TextEditingController(text: p.age > 0 ? '${p.age}' : '');
    _income = TextEditingController(
        text: p.monthlyIncome > 0 ? p.monthlyIncome.toStringAsFixed(0) : '');
    _rate = TextEditingController(
        text: p.hourlyRate > 0 ? p.hourlyRate.toStringAsFixed(0) : '');
    _persona = p.persona;
    _type = p.incomeType;
    _daysPerWeek = p.workDaysPerWeek;
    _hoursPerDay = p.hoursPerDay;
    _workDayStartHour = p.workDayStartHour;
    _overtimePaid = p.overtimePaid;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _income.dispose();
    _rate.dispose();
    super.dispose();
  }

  bool get _isAllowance => _type == IncomeType.allowance;
  double get _monthly => double.tryParse(_income.text) ?? 0;

  double get _effectiveRate {
    if (_isAllowance) return 0;
    if (_type == IncomeType.hourly) return double.tryParse(_rate.text) ?? 0;
    final hours = _daysPerWeek * 4.33 * _hoursPerDay;
    return hours <= 0 ? 0 : _monthly / hours;
  }

  bool get _valid => _isAllowance ? _monthly > 0 : _effectiveRate > 0;

  void _save() {
    final p = ref.read(profileOrDefaultProvider);
    final next = p.copyWith(
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
    ref.read(appActionsProvider).saveProfile(next);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          Text('Persona', style: t.titleLarge),
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
          Text('Income source', style: t.titleLarge),
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
            _moneyField(_rate, 'Hourly rate (₹)')
          else
            _moneyField(
                _income,
                _isAllowance
                    ? 'Monthly pocket money (₹)'
                    : 'Monthly income (₹)'),
          if (!_isAllowance) ...[
            const SizedBox(height: 20),
            _slider('Work days / week', _daysPerWeek, 1, 7, 6,
                (v) => setState(() => _daysPerWeek = v)),
            _slider('Hours / day', _hoursPerDay, 1, 16, 15,
                (v) => setState(() => _hoursPerDay = v)),
            const SizedBox(height: 8),
            Text('Shift', style: t.bodyMedium),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Overtime is paid'),
              subtitle: const Text('Earn for hours beyond your daily target'),
              value: _overtimePaid,
              onChanged: (v) => setState(() => _overtimePaid = v),
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isAllowance ? 'Monthly budget' : 'Time value',
                    style: t.labelSmall),
                const SizedBox(height: 6),
                Text(
                  _isAllowance
                      ? '${fmt.format(_monthly)} / month'
                      : '${fmt.format(_effectiveRate)} / hour',
                  style: t.displayLarge?.copyWith(color: AppColors.time),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _valid ? _save : null,
            child: const Text('Save changes'),
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
