import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/app_providers.dart';

class TimeWalletApp extends ConsumerWidget {
  const TimeWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'TimeWallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const _Splash(),
      error: (e, _) => _ErrorView(message: '$e'),
      data: (user) {
        if (user == null) {
          // Signed out → straight to login. The pre-signup teaching flow was
          // removed (it felt repetitive against the post-signup onboarding,
          // especially for founders); the "money is time" aha now lives on the
          // login screen's demo card, and all profile questions are asked once,
          // after signup, in OnboardingScreen.
          return const LoginScreen();
        }

        // Email/password accounts must verify before entering. Google accounts
        // arrive with emailVerified == true and pass straight through.
        if (!user.emailVerified) return const VerifyEmailScreen();

        // Signed in: decide onboarding vs home from the profile doc.
        final profile = ref.watch(profileProvider);
        return profile.when(
          loading: () => const _Splash(),
          error: (e, _) => _ErrorView(message: '$e'),
          data: (p) => (p != null && p.onboarded)
              ? const HomeShell()
              : const OnboardingScreen(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              child: Image(
                image: AssetImage('assets/logo.png'),
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong. Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                // A permission-denied here is almost always a stale ID token
                // whose email_verified claim lags behind the just-verified
                // account. Mint a fresh token before re-reading, otherwise
                // "Try again" re-runs with the same stale claim and loops.
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).refreshIdToken();
                  } catch (_) {
                    // Offline / no user — fall through to a plain re-read.
                  }
                  ref.invalidate(authStateProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
