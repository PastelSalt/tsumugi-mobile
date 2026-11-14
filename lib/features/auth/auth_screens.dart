import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/tokens.dart';
import 'auth_widgets.dart';

const _loginStates = [
  ('default', 'Default'),
  ('errors', 'Field errors'),
  ('invalid', 'Invalid credentials'),
  ('locked', 'Locked account'),
  ('unavailable', 'Service unavailable'),
];
const _registerStates = [
  ('default', 'Default'),
  ('errors', 'Field errors'),
  ('exists', 'Email already used'),
  ('pending', 'Pending verification'),
  ('success', 'Success layout'),
];
const _forgotStates = [
  ('default', 'Default'),
  ('invalid', 'Malformed email'),
  ('sent', 'Confirmation'),
  ('unavailable', 'Service unavailable'),
];
const _resetStates = [
  ('default', 'Default'),
  ('weak', 'Weak password'),
  ('mismatch', 'Mismatch'),
  ('expired', 'Expired link'),
  ('success', 'Success layout'),
];

String _state(String? raw, List<(String, String)> states) =>
    states.any((s) => s.$1 == raw) ? raw! : 'default';

Widget _toWorkspace(
  BuildContext context, {
  String label = 'Continue to demo workspace',
}) => FilledButton(onPressed: () => context.go('/home'), child: Text(label));

class _Link extends StatelessWidget {
  const _Link(this.lead, this.label, this.route);

  final String lead;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (lead.isNotEmpty) Text('$lead '),
      TextButton(onPressed: () => context.go(route), child: Text(label)),
    ],
  );
}

/// Demo-mode login (website `AuthPage` login). Submitting goes straight to the workspace; nothing
/// typed is read.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.preview});

  final String? preview;

  @override
  Widget build(BuildContext context) {
    final state = _state(preview, _loginStates);
    final banners = {
      'invalid': (
        'Email or password not recognized',
        'Check them and try again, or reset your password.',
      ),
      'locked': (
        'This account is temporarily locked',
        'Too many attempts were made. Try again later or reset your password.',
      ),
      'unavailable': (
        'Sign-in is unavailable right now',
        'Please try again in a few minutes.',
      ),
      'errors': (
        'Check the highlighted fields',
        'Two fields need attention before you can continue.',
      ),
    };
    final banner = banners[state];
    final errors = state == 'errors';
    return AuthShell(
      title: 'Welcome back to the thread.',
      intro: 'Sign in to continue shaping the work that matters.',
      states: _loginStates,
      currentState: state,
      note: 'Use a private device and keep your sign-in details secure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner != null) FormBanner(title: banner.$1, message: banner.$2),
          AuthTextField(
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            error: errors ? 'Enter your email address.' : null,
          ),
          AuthPasswordField(
            label: 'Password',
            error: errors ? 'Enter your password.' : null,
          ),
          const _Link('', 'Forgot password?', '/forgot-password'),
          const SizedBox(height: AppTokens.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Link('New to Tsumugi?', 'Create account', '/register'),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Log in'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Continue as demo user'),
          ),
        ],
      ),
    );
  }
}

/// Demo-mode sign-up with its pending and success layouts.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.preview});

  final String? preview;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    final state = _state(widget.preview, _registerStates);
    if (state == 'pending' || state == 'success') {
      final pending = state == 'pending';
      return AuthShell(
        title: pending ? 'Check your inbox.' : 'You’re in the thread.',
        intro: 'This is a layout preview of the next step. No account was created.',
        states: _registerStates,
        currentState: state,
        child: StatusPanel(
          icon: pending ? LucideIcons.mailCheck : LucideIcons.circleCheck,
          title: pending ? 'Confirm your email address' : 'Account created',
          message: pending
              ? 'A verification link would be sent to your address. Nothing was sent in this demo.'
              : 'In the real flow this confirms the new account. In the demo, continue to the sample workspace.',
          actions: [_toWorkspace(context)],
        ),
      );
    }
    final errors = state == 'errors';
    return AuthShell(
      title: 'Start your next thread.',
      intro: 'Create a home for the ideas, requirements, and deliverables you are bringing together.',
      states: _registerStates,
      currentState: state,
      note: 'Your project thread starts with a clear place to begin.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errors)
            const FormBanner(
              title: 'Check the highlighted fields',
              message: 'Five fields need attention before an account could be created.',
            ),
          if (state == 'exists')
            const FormBanner(
              title: 'That email is already in use',
              message: 'Log in instead, or use a different address.',
            ),
          AuthTextField(
            label: 'Display name',
            hint: 'Your name',
            error: errors ? 'Enter a display name.' : null,
          ),
          AuthTextField(
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            error: errors
                ? 'Enter an email address like name@example.com.'
                : (state == 'exists'
                      ? 'This email already has an account.'
                      : null),
          ),
          AuthPasswordField(
            label: 'Password',
            showRequirements: true,
            error: errors ? 'Choose a stronger password.' : null,
          ),
          AuthPasswordField(
            label: 'Confirm password',
            hint: false,
            error: errors ? 'The passwords do not match.' : null,
          ),
          _Agreement(
            error: errors ? 'Accept the Terms of Service to continue.' : null,
          ),
          const SizedBox(height: AppTokens.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Link('Already have an account?', 'Log in', '/login'),
              FilledButton(
                onPressed: () => showDemoSubmitSheet(
                  context,
                  title: 'Account creation isn’t connected yet',
                  body: 'This is where a new account would be created. In this demo nothing you entered was read, stored, or sent, and no account exists.',
                  actions: [_toWorkspace(context)],
                ),
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Agreement extends StatefulWidget {
  const _Agreement({this.error});

  final String? error;

  @override
  State<_Agreement> createState() => _AgreementState();
}

class _AgreementState extends State<_Agreement> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _checked,
          onChanged: (v) => setState(() => _checked = v ?? false),
          title: const Text(
            'I agree to the Terms of Service and acknowledge the Privacy Policy and Cookie & Local Storage Policy.',
          ),
        ),
        Wrap(
          children: [
            TextButton(
              onPressed: () => context.push('/legal/terms-of-service'),
              child: const Text('Terms of Service'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/privacy-policy'),
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () =>
                  context.push('/legal/cookie-and-local-storage-policy'),
              child: const Text('Cookie & Local Storage Policy'),
            ),
          ],
        ),
        if (widget.error != null)
          Text(
            widget.error!,
            style: TextStyle(color: t.pink, fontSize: AppTokens.textMeta),
          ),
      ],
    );
  }
}

/// Forgot-password layout with its confirmation state. No email is sent.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.preview});

  final String? preview;

  @override
  Widget build(BuildContext context) {
    final state = _state(preview, _forgotStates);
    if (state == 'sent') {
      return AuthShell(
        title: 'Check your inbox.',
        intro: 'This is a layout preview. No email was sent.',
        states: _forgotStates,
        currentState: state,
        child: StatusPanel(
          icon: LucideIcons.mailCheck,
          title: 'If an account exists, a link is on its way',
          message: 'The message wording is deliberately the same whether or not an account exists.',
          actions: [
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to log in'),
            ),
          ],
        ),
      );
    }
    return AuthShell(
      title: 'Forgot your password?',
      intro: 'Enter the email address for your account and we’ll send a link to choose a new password.',
      states: _forgotStates,
      currentState: state,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state == 'unavailable')
            const FormBanner(
              title: 'Recovery is unavailable right now',
              message: 'Please try again in a few minutes.',
            ),
          AuthTextField(
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            error: state == 'invalid'
                ? 'Enter an email address like name@example.com.'
                : null,
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Link('', 'Back to log in', '/login'),
              FilledButton(
                onPressed: () => showDemoSubmitSheet(
                  context,
                  title: 'No email is sent in this demo',
                  body: 'In the real flow a single-use link would be emailed to the address you entered. Nothing you typed was read or sent here.',
                ),
                child: const Text('Send reset link'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reset-password layout with weak, mismatch, expired and success states. Nothing is changed.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, this.preview});

  final String? preview;

  @override
  Widget build(BuildContext context) {
    final state = _state(preview, _resetStates);
    if (state == 'expired' || state == 'success') {
      final expired = state == 'expired';
      return AuthShell(
        title: expired ? 'That link has expired.' : 'Password updated.',
        intro: 'This is a layout preview. No password was changed.',
        states: _resetStates,
        currentState: state,
        child: StatusPanel(
          title: expired ? 'Request a new link' : 'You can log in again',
          message: expired
              ? 'Reset links work once and for a short time. Request another to continue.'
              : 'In the real flow this confirms the change. Nothing was saved in the demo.',
          actions: [
            FilledButton(
              onPressed: () =>
                  context.go(expired ? '/forgot-password' : '/login'),
              child: Text(expired ? 'Send a new link' : 'Back to log in'),
            ),
          ],
        ),
      );
    }
    return AuthShell(
      title: 'Choose a new password.',
      intro: 'Pick something strong that you don’t use anywhere else.',
      states: _resetStates,
      currentState: state,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthPasswordField(
            label: 'New password',
            showRequirements: true,
            error: state == 'weak' ? 'Choose a stronger password.' : null,
          ),
          AuthPasswordField(
            label: 'Confirm new password',
            hint: false,
            error: state == 'mismatch' ? 'The passwords do not match.' : null,
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Link('', 'Back to log in', '/login'),
              FilledButton(
                onPressed: () => showDemoSubmitSheet(
                  context,
                  title: 'No password is changed in this demo',
                  body: 'In the real flow this would set the new password. Nothing you typed was read, stored, or sent here.',
                  actions: [
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to log in'),
                    ),
                  ],
                ),
                child: const Text('Update password'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
