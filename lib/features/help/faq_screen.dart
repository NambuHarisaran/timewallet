import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_body.dart';

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final Map<String, List<_FaqItem>> _categories = {
    'General': [
      const _FaqItem(
        'What is TimeWallet?',
        'TimeWallet is a personal finance app that helps you view the cost of items in terms of the work hours required to earn them. By thinking in "time" instead of just "money", it helps you make more deliberate spending decisions.',
      ),
      const _FaqItem(
        'How does the app turn money into time?',
        'We calculate your Effective Hourly Rate (EHR) based on your take-home pay and the actual hours you work. Whenever you log an expense, the app divides the price by your EHR to show you the equivalent hours of work it cost you.',
      ),
    ],
    'Work & Reminders': [
      const _FaqItem(
        'Why should I log my work time?',
        'Logging your daily work hours allows TimeWallet to show how much time and money you\'ve earned today. It helps build awareness of your day-to-day work efforts compared to your daily expenses.',
      ),
      const _FaqItem(
        'What is the daily reminder for?',
        'It is a gentle daily nudge to log your work hours or record any expenses for the day. You can customize the reminder time in your Profile settings.',
      ),
    ],
    'Hold & Reclaimed Time': [
      const _FaqItem(
        'How does the "Hold" feature work?',
        'When you want to buy a non-essential item, you can put it on a 24-hour "Hold" in the app. This cooling-off period gives you a chance to think it over. After 24 hours, you decide: buy it, or skip it and keep your time.',
      ),
      const _FaqItem(
        'What is "Reclaimed Time"?',
        'Reclaimed Time is the hours of work-time you successfully saved by choosing to "skip" non-essential purchases that you had put on hold. It is a direct measure of the time you\'ve bought back for yourself.',
      ),
    ],
    'Security & Settings': [
      const _FaqItem(
        'Where is my financial data stored?',
        'Your profile data is stored securely in Firebase and is only accessible to you. Financial entries and calculations are also cached on your device. We never share or sell your financial data.',
      ),
      const _FaqItem(
        'Can I switch back to standard budgeting?',
        'Yes. If you prefer to track spending without converting to work-time, you can enable "Budget Mode" in your Profile settings. This lets you track spending against monthly category budgets.',
      ),
    ],
  };

  String? _expandedQuestion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        elevation: 0,
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 4),
              child: Text(
                'Got questions? We have answers.',
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
            ..._categories.entries.expand((category) {
              return [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
                  child: Text(
                    category.key.toUpperCase(),
                    style: t.labelMedium?.copyWith(
                      color: AppColors.muted(context),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...category.value.map((item) {
                  final isExpanded = _expandedQuestion == item.question;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExpanded
                                ? AppColors.accent.withValues(alpha: 0.5)
                                : AppColors.border(context),
                            width: isExpanded ? 1.5 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ExpansionTile(
                            key: PageStorageKey<String>(item.question),
                            initiallyExpanded: isExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expandedQuestion = expanded ? item.question : null;
                              });
                            },
                            title: Text(
                              item.question,
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isExpanded ? AppColors.accent : null,
                              ),
                            ),
                            iconColor: AppColors.accent,
                            collapsedIconColor: AppColors.muted(context),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              Text(
                                item.answer,
                                style: t.bodyMedium?.copyWith(
                                  height: 1.5,
                                  color: AppColors.text(context).withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ];
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
