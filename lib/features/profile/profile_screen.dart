import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../history/history_screen.dart';
import '../salary/salary_setup_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _personaLabel = {
    Persona.student: 'Student',
    Persona.freelancer: 'Freelancer',
    Persona.employee: 'Employee',
    Persona.owner: 'Business owner',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final mode = ref.watch(themeModeProvider);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final email = ref.watch(firebaseAuthProvider).currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          // Identity header
          SectionCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.money,
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name.characters.first.toUpperCase()
                        : '🙂',
                    style: const TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isNotEmpty ? profile.name : 'Add your name',
                        style: t.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (profile.age > 0) '${profile.age} yrs',
                          _personaLabel[profile.persona]!,
                        ].join(' · '),
                        style: t.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EditProfileScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientCard(
            colors: AppColors.auroraViolet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.tracksTime ? 'YOUR TIME VALUE' : 'MONTHLY BUDGET',
                    style: t.labelSmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  profile.tracksTime
                      ? '${fmt.format(profile.effectiveHourlyRate)} / hour'
                      : '${fmt.format(profile.monthlyMoney)} / month',
                  style: t.displayLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.tracksTime
                      ? '${profile.workDaysPerWeek.toStringAsFixed(0)} days/wk · '
                          '${profile.hoursPerDay.toStringAsFixed(0)}h/day'
                      : 'Pocket-money mode — spending tracked against budget',
                  style: t.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  value: mode == ThemeMode.dark,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                      v ? ThemeMode.dark : ThemeMode.light,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Activity log'),
                  subtitle: const Text('Your recent expenses, work & investments'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HistoryScreen())),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune),
                  title: const Text('Edit profile & income'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EditProfileScreen())),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reset salary setup'),
                  subtitle: const Text('Clear income and re-enter it'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _resetSalary(context, ref),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.warn),
                  title: const Text('Sign out'),
                  onTap: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Danger zone
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever, color: AppColors.warn),
              title: const Text('Delete account'),
              subtitle:
                  const Text('Permanently erase all your data and account'),
              onTap: () => _deleteAccount(context, ref),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(email, style: t.labelSmall)),
          const SizedBox(height: 8),
          Center(child: Text('TimeWallet · v0.1 MVP', style: t.labelSmall)),
          ],
        ),
      ),
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

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently erases your profile, expenses, goals, holdings '
            'and history, then deletes your account. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await ref.read(appActionsProvider).deleteAccountAndData();
    // Success: auth stream flips -> AuthGate routes to login automatically.
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
