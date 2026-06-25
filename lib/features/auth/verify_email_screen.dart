import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';

/// Shown when a signed-in user's email is not yet verified. Blocks access to the
/// app until they confirm. Google sign-ins arrive pre-verified and skip this.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _busy = false;

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).resendVerification();
      _toast('Verification email sent.');
    } catch (e) {
      _toast(AuthService.describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.reloadUser();
      if (auth.current?.emailVerified ?? false) {
        // Auth stream doesn't re-emit on verification — force AuthGate to
        // re-evaluate against the now-refreshed currentUser.
        ref.invalidate(authStateProvider);
      } else {
        _toast('Not verified yet. Check your inbox (and spam).');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final email =
        ref.watch(firebaseAuthProvider).currentUser?.email ?? 'your email';
    return Scaffold(
      body: ResponsiveBody(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(Icons.mark_email_unread_outlined,
                  size: 56, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),
            Text('Verify your email',
                textAlign: TextAlign.center, style: t.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'We sent a verification link to $email. Open it, then tap "I\'ve verified".',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _busy ? null : _refresh,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text("I've verified"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _resend,
              child: const Text('Resend email'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => ref.read(authServiceProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
