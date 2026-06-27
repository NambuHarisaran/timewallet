import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

class _Term {
  final IconData icon;
  final String word, meaning;
  const _Term(this.icon, this.word, this.meaning);
}

const _terms = <_Term>[
  _Term(Icons.hourglass_bottom, 'Money as time',
      'Every price is shown as the work-time it costs you. If you earn ₹500/hour, a ₹500 buy costs you 1 hour of your life.'),
  _Term(Icons.payments_outlined, 'Effective hourly rate',
      'What an hour of your life is really worth: your monthly take-home divided by the hours you actually work each month. TimeWallet uses this to turn rupees into time.'),
  _Term(Icons.timer_outlined, 'Log work time',
      'Tap this as you work so the app knows how many hours you put in today. Your "Earned today" grows with each hour logged.'),
  _Term(Icons.more_time, 'Overtime',
      'Hours worked beyond your normal daily hours. It only adds to your earnings if you marked your overtime as paid in your profile.'),
  _Term(Icons.pause_circle_outline, 'Hold (24h)',
      'Put a "want" on a 24-hour pause before buying it. After a day you decide with a clear head — Buy it, or Skip and keep the time.'),
  _Term(Icons.celebration_outlined, 'Reclaimed time',
      'The work-time you saved by skipping wants you had on hold. It adds up — proof of the life you bought back.'),
  _Term(Icons.shopping_bag_outlined, 'Need vs Want',
      'Tag each expense. Needs are unavoidable; wants are optional. Seeing how much time your wants cost makes impulse buys easier to skip.'),
  _Term(Icons.flag_outlined, 'Goals in work-days',
      'A savings goal shown as the number of work-days — and overtime per day — it takes to reach. Time, not just a rupee target.'),
  _Term(Icons.subscriptions_outlined, 'Subscription time-tax',
      'Your recurring bills added up and shown as the work-time they cost every month. The hours you work just to keep them running.'),
  _Term(Icons.account_balance_wallet_outlined, 'Budget mode',
      'If you have pocket money or no fixed income, the app tracks spending against a monthly budget instead of converting to work-time.'),
];

/// Plain-language glossary of every TimeWallet term. Reached from Profile and
/// from the end of the walkthrough — the always-available "what does this mean".
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('What the words mean')),
      body: ContentWidth(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _terms.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final term = _terms[i];
            return SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(term.icon, size: 26, color: AppColors.money),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(term.word, style: t.titleMedium),
                        const SizedBox(height: 4),
                        Text(term.meaning,
                            style: t.bodyMedium?.copyWith(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
