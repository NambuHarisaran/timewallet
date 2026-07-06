import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../utils/browser_detector.dart' as detector;
import 'login_demo_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // Signup is the default for brand-new installs, but returning users
  // shouldn't have to toggle every session — remember the last mode (U12).
  static const _modeKey = 'lastAuthModeSignUp';
  bool _isSignUp = true;
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = ref.read(sharedPrefsProvider).getBool(_modeKey) ?? true;
  }

  void _setMode(bool signUp) {
    ref.read(sharedPrefsProvider).setBool(_modeKey, signUp);
    setState(() => _isSignUp = signUp);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Signup requires a stronger password than Firebase's 6-char minimum.
  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.length > 128) return 'Too long (max 128 characters)';
    if (!_isSignUp) return s.length < 6 ? 'Min 6 characters' : null;
    if (s.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Mix letters and numbers';
    }
    return null;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = ref.read(authServiceProvider);
    try {
      if (_isSignUp) {
        await auth.signUpEmail(_email.text, _password.text);
        _toast('Account created. Verification email sent to ${_email.text.trim()}.');
      } else {
        await auth.signInEmail(_email.text, _password.text);
      }
      // authStateProvider stream flips -> AuthGate routes away.
    } catch (e) {
      _toast(AuthService.describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      final cred = await ref.read(authServiceProvider).signInGoogle();
      if (cred == null) {
        // Redirect flow (mobile web) — the page will reload after Google
        // authenticates. Keep the spinner; no further action needed here.
        if (kIsWeb) return;
        
        // Native mobile user cancelled or failed — stop the spinner.
        if (mounted) setState(() => _busy = false);
        return;
      }
      // Popup flow succeeded — authStateProvider stream flips → AuthGate
      // routes away automatically.
    } catch (e) {
      _toast(AuthService.describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      _toast('Enter your email first.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(_email.text);
      _toast('Password reset email sent.');
    } catch (e) {
      _toast(AuthService.describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isSessionStorageUnsupported = !detector.isSessionStorageSupported();
    final isInAppWebView = detector.isInAppWebView();
    return Scaffold(
      body: ResponsiveBody(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.45),
                            blurRadius: 30,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset('assets/logo.png',
                            width: 96, height: 96, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('TimeWallet',
                      textAlign: TextAlign.center, style: t.displayLarge),
                  const SizedBox(height: 6),
                  Text('See your money as time.',
                      textAlign: TextAlign.center, style: t.bodyMedium),
                  const SizedBox(height: 24),
                  const LoginDemoCard(),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                  ],
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _forgot,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _submitEmail,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isSignUp ? 'Create account' : 'Log in'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: t.labelSmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isSessionStorageUnsupported || isInAppWebView) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warn.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.warn.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warn, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isSessionStorageUnsupported
                                  ? 'Browser storage is disabled or inaccessible (e.g., Incognito mode). Google Sign-In will fail. Please use Email/Password login or enable cookies/storage.'
                                  : 'Google Sign-In might not work inside this app\'s browser. If login fails, please tap the menu (three dots) and select "Open in Browser" (e.g. Chrome/Safari) to sign in.',
                              style: t.bodySmall?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _google,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    icon: const Text('G',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.money,
                            fontSize: 18)),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account?'
                            : "Don't have an account?",
                        style: t.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => _setMode(!_isSignUp),
                        child: Text(_isSignUp ? 'Log in' : 'Sign up'),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
