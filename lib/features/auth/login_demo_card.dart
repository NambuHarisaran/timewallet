import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/time/time_engine.dart';
import '../../core/util/formatters.dart';
import '../../widgets/gradient_card.dart';

/// X1 — the aha moment BEFORE the signup wall. A self-contained live demo:
/// drag a monthly income, watch what ₹500 really costs in working life.
/// No providers, no persistence — display only.
class LoginDemoCard extends StatefulWidget {
  const LoginDemoCard({super.key});

  @override
  State<LoginDemoCard> createState() => _LoginDemoCardState();
}

class _LoginDemoCardState extends State<LoginDemoCard> {
  static const double _example = 500;
  double _income = 50000;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rate = TimeEngine.rateFromMonthly(
      netMonthlyIncome: _income,
      workDaysPerWeek: 5,
      hoursPerDay: 8,
    );
    final minutes = rate > 0 ? (_example / rate) * 60 : 0.0;
    final timeStr = TimeFormat.longForm(minutes);

    return GradientCard(
      colors: AppColors.heroNeutral,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRY IT — ${moneyFmt.format(_example)} REALLY COSTS YOU',
              style: t.labelSmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(timeStr,
                maxLines: 1,
                style: t.headlineMedium?.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 2),
          Text(
            'of working life at ${moneyFmt.format(_income)}/month. Drag to try yours.',
            style: t.bodySmall?.copyWith(color: Colors.white70),
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
    );
  }
}
