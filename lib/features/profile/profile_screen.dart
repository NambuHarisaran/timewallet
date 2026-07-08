import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/formatters.dart';
import '../../services/export_service.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../../widgets/time_card.dart';
import '../budgets/budgets_screen.dart';
import '../expense/expenses_screen.dart';
import '../history/history_screen.dart';
import '../insights/insights_screen.dart';
import '../reclaimed/achievements_screen.dart';
import '../recurring/recurring_screen.dart';
import '../help/glossary_screen.dart';
import '../help/faq_screen.dart';
import '../salary/salary_setup_screen.dart';
import '../walkthrough/walkthrough_screen.dart';
import '../wrapped/wrapped_screen.dart';
import 'edit_profile_screen.dart';
import 'delete_confirmation_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final mode = ref.watch(themeModeProvider);
    final fmt = moneyFmt;
    final email = ref.watch(firebaseAuthProvider).currentUser?.email ?? '';

    // Read BEFORE any inner Scaffold resets MediaQuery (same pattern as dashboard).
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    const double navPill = 92;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, safeBottom + navPill),
            children: [
          // Inline title — mirrors dashboard "Good morning" header
          Text('Profile',
              style: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Identity header — the Time Card the user designed in onboarding.
          // Their own artifact greets them here every session (IKEA effect).
          TimeCard(profile: profile),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style:
                      t.bodySmall?.copyWith(color: AppColors.muted(context)),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit profile'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EditProfileScreen())),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // The Time Card already shows the headline rate/budget, so this
          // strip adds only what it doesn't: the work schedule (or budget
          // mode) and the true-wage insight when the user has entered
          // commute/work-cost deductions — no duplicated hero number.
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      profile.tracksTime
                          ? Icons.schedule
                          : Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: AppColors.muted(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        profile.tracksTime
                            ? '${profile.workDaysPerWeek.toStringAsFixed(0)} days/wk · '
                                '${profile.hoursPerDay.toStringAsFixed(0)}h/day'
                            : 'Pocket-money mode — spending tracked against budget',
                        style: t.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (profile.tracksTime && profile.hasTrueWageInputs) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.trending_down,
                          size: 18, color: AppColors.warn),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Real wage ${fmt.format(profile.trueHourlyRate)}/hr'
                          '  ·  ${(profile.trueWageDropPct * 100).round()}% less',
                          style: t.bodyMedium?.copyWith(
                              color: AppColors.warn,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Grouped into scannable sections (U8): Learn / Your money /
          // Settings / Account — one entry per destination.
          SectionCard(
            title: 'LEARN',
            child: Column(
              children: [
                _tile(context, Icons.help_outline, 'How it works',
                    'Replay the feature walkthrough', const WalkthroughScreen()),
                const Divider(),
                _tile(context, Icons.question_answer_outlined, 'FAQ',
                    'Frequently asked questions', const FaqScreen()),
                const Divider(),
                _tile(context, Icons.menu_book_outlined, 'What the words mean',
                    'Plain-language glossary of every term',
                    const GlossaryScreen()),
                const Divider(),
                _tile(context, Icons.emoji_events_outlined, 'Achievements',
                    'Life reclaimed by skipping wants',
                    const AchievementsScreen()),
                const Divider(),
                _tile(context, Icons.auto_awesome_outlined, 'Your Wrapped',
                    'Your money→time recap', const WrappedScreen()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'YOUR MONEY',
            child: Column(
              children: [
                _tile(context, Icons.receipt_long_outlined, 'All expenses',
                    'Monitor & delete your spending', const ExpensesScreen()),
                const Divider(),
                _tile(context, Icons.insights_outlined, 'Insights',
                    'Spending trends & breakdowns', const InsightsScreen()),
                const Divider(),
                _tile(context, Icons.pie_chart_outline, 'Category budgets',
                    'Set monthly limits per category', const BudgetsScreen()),
                const Divider(),
                _tile(context, Icons.subscriptions_outlined, 'Subscriptions',
                    'Track recurring costs as work-time',
                    const RecurringScreen()),
                const Divider(),
                _tile(context, Icons.history, 'Activity log',
                    'Your recent expenses, work & investments',
                    const HistoryScreen()),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Export expenses (CSV)'),
                  subtitle: const Text('Copy CSV to clipboard for backup'),
                  onTap: () => _exportCsv(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'SETTINGS',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  value: mode == ThemeMode.dark,
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).setDark(v),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily reminder'),
                  subtitle: const Text('A nudge to log work & spending'),
                  value: ref.watch(dailyReminderProvider),
                  onChanged: (v) =>
                      ref.read(dailyReminderProvider.notifier).set(v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: ref.watch(dailyReminderProvider),
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Reminder time'),
                  subtitle: Text(_hourLabel(ref.watch(reminderHourProvider))),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickReminderHour(context, ref),
                ),
                const Divider(),
                _tile(context, Icons.tune, 'Edit profile & income', null,
                    const EditProfileScreen()),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reset salary setup'),
                  subtitle: const Text('Clear income and re-enter it'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _resetSalary(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ACCOUNT',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.warn),
                  title: const Text('Sign out'),
                  onTap: () => ref.read(authServiceProvider).signOut(),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.delete_forever, color: AppColors.warn),
                  title: const Text('Delete account'),
                  subtitle:
                      const Text('Permanently erase all your data and account'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeleteConfirmationScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(email, style: t.labelSmall)),
          const SizedBox(height: 8),
          // Keep in sync with pubspec.yaml `version:` (U9).
          Center(child: Text('TimeWallet · v1.0.0', style: t.labelSmall)),
          const SizedBox(height: 24),
          // aqrostudios Developer Banner
          GestureDetector(
            onTap: () async {
              final url = Uri.parse('https://www.aqro.in/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF1B1E28), const Color(0xFF14161C)]
                      : [const Color(0xFFFFFFFF), const Color(0xFFF5F4F0)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                     borderRadius: BorderRadius.circular(6),
                     child: Image.asset(
                       Theme.of(context).brightness == Brightness.dark
                           ? 'assets/aqro_logo_white.png'
                           : 'assets/aqro_logo_black.png',
                       height: 28,
                       width: 28,
                       fit: BoxFit.contain,
                     ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DEVELOPED BY',
                        style: t.labelSmall?.copyWith(
                          color: AppColors.muted(context),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'aqrostudios',
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),      // ListView
      ),        // ContentWidth
    ),          // SafeArea
  );            // Scaffold
  }

  String _hourLabel(int hour) {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return 'Every day at $h12:00 ${hour < 12 ? 'AM' : 'PM'}';
  }

  Future<void> _pickReminderHour(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reminderHourProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current, minute: 0),
      helpText: 'When should we nudge you?',
    );
    // Hour granularity is deliberate: the schedule uses inexact alarms anyway.
    if (picked != null) {
      await ref.read(reminderHourProvider.notifier).set(picked.hour);
    }
  }

  /// Standard navigation tile — one look for every destination (U8).
  Widget _tile(BuildContext context, IconData icon, String title,
      String? subtitle, Widget destination) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => destination)),
    );
  }

  Future<void> _resetSalary(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset salary setup?'),
        content: const Text(
            'Your income details will be cleared so you can enter them again. '
            'Expenses, goals and investments are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(appActionsProvider).resetSalary();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SalarySetupScreen()),
    );
  }
  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final expenses = ref.read(expensesProvider).asData?.value ?? const [];
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No expenses to export yet.')));
      return;
    }
    final csv = ExportService.expensesCsv(expenses);
    await Clipboard.setData(ClipboardData(text: csv));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expenses CSV copied to clipboard.')),
      );
    }
  }
}
