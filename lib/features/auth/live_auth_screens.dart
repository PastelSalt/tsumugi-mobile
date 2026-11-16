import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/net/api_client.dart';
import '../../core/net/auth_state.dart';
import '../../core/theme/tokens.dart';
import 'auth_widgets.dart';

// Real sign-in and sign-up (the server). The layouts in `auth_screens.dart` (/login, /register) are the demo-mode
// design previews and read nothing. The demo itself is entered from Welcome and never reaches this code.

/// Plain-words message for a failed sign-in or sign-up.
({String title, String message}) _bannerFor(ApiError e) => switch (e.code) {
  'auth.invalid_credentials' => (
    title: 'Email or password not recognized',
    message: 'Check them and try again.',
  ),
  'auth.locked' => (
    title: 'This account is temporarily locked',
    message: 'Too many attempts were made. Try again in a few minutes.',
  ),
  'auth.email_taken' => (
    title: 'That email is already in use',
    message: 'Log in instead, or use a different address.',
  ),
  'rate_limited' => (
    title: 'Too many attempts',
    message: 'Please wait a moment and try again.',
  ),
  'network' => (
    title: 'Can’t reach Tsumugi',
    message: 'Check your connection, and that the server is running.',
  ),
  _ => (title: 'That didn’t work', message: e.message),
};

class LiveSignInScreen extends ConsumerStatefulWidget {
  const LiveSignInScreen({super.key});

  @override
  ConsumerState<LiveSignInScreen> createState() => _LiveSignInState();
}

class _LiveSignInState extends ConsumerState<LiveSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  ({String title, String message})? _banner;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _emailError = email.isEmpty ? 'Enter your email address.' : null;
      _passwordError = password.isEmpty ? 'Enter your password.' : null;
      _banner = null;
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).login(email, password);
      if (mounted) context.go('/home');
    } on ApiError catch (e) {
      if (mounted) setState(() => _banner = _bannerFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
    title: 'Welcome back to the thread.',
    intro: 'Sign in to continue shaping the work that matters.',
    note: 'Use a private device and keep your sign-in details secure.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_banner != null)
          FormBanner(title: _banner!.title, message: _banner!.message),
        AuthTextField(
          label: 'Email address',
          hint: 'you@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          error: _emailError,
        ),
        AuthPasswordField(
          label: 'Password',
          hint: false,
          controller: _password,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          error: _passwordError,
        ),
        const SizedBox(height: AppTokens.space2),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('New to Tsumugi? '),
                TextButton(
                  onPressed: () => context.go('/sign-up'),
                  child: const Text('Create account'),
                ),
              ],
            ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Signing in…' : 'Log in'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space2),
        TextButton(
          onPressed: () {
            ref.read(authProvider.notifier).enterDemo();
            context.go('/home');
          },
          child: const Text('Try the demo instead (no account)'),
        ),
      ],
    ),
  );
}

class LiveSignUpScreen extends ConsumerStatefulWidget {
  const LiveSignUpScreen({super.key});

  @override
  ConsumerState<LiveSignUpScreen> createState() => _LiveSignUpState();
}

class _LiveSignUpState extends ConsumerState<LiveSignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = false;
  bool _busy = false;
  ({String title, String message})? _banner;
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final problems = <String, String>{
      if (name.isEmpty) 'name': 'Enter a display name.',
      if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email))
        'email': 'Enter an email address like name@example.com.',
      if (password.length < 12) 'password': 'Use at least 12 characters.',
      if (password != _confirm.text) 'confirm': 'The passwords do not match.',
      if (!_agree) 'agree': 'Accept the Terms of Service to continue.',
    };
    setState(() {
      _errors
        ..clear()
        ..addAll(problems);
      _banner = problems.isEmpty
          ? null
          : (
              title: 'Check the highlighted fields',
              message: 'Some details need attention before an account can be created.',
            );
    });
    if (problems.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .register(email: email, password: password, displayName: name);
      if (mounted) context.go('/home');
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _banner = _bannerFor(e);
        final pw = e.fieldMessage('password');
        if (pw != null) _errors['password'] = pw;
        if (e.code == 'auth.email_taken') {
          _errors['email'] = 'This email already has an account.';
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
    title: 'Start your next thread.',
    intro:
        'Create a home for the ideas, requirements, and deliverables you are bringing together.',
    note: 'Your account is stored on the Tsumugi server you connect to.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_banner != null)
          FormBanner(title: _banner!.title, message: _banner!.message),
        AuthTextField(
          label: 'Display name',
          hint: 'Your name',
          controller: _name,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          error: _errors['name'],
        ),
        AuthTextField(
          label: 'Email address',
          hint: 'you@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          error: _errors['email'],
        ),
        AuthPasswordField(
          label: 'Password',
          hint: false,
          showRequirements: true,
          controller: _password,
          autofillHints: const [AutofillHints.newPassword],
          error: _errors['password'],
        ),
        AuthPasswordField(
          label: 'Confirm password',
          hint: false,
          controller: _confirm,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(),
          error: _errors['confirm'],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _agree,
          onChanged: (v) => setState(() => _agree = v ?? false),
          title: const Text(
            'I agree to the Terms of Service and acknowledge the Privacy Policy and Cookie & Local Storage Policy.',
          ),
          subtitle: _errors['agree'] == null
              ? null
              : Text(
                  _errors['agree']!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account? '),
                TextButton(
                  onPressed: () => context.go('/sign-in'),
                  child: const Text('Log in'),
                ),
              ],
            ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Creating…' : 'Create account'),
            ),
          ],
        ),
      ],
    ),
  );
}
