import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/tokens.dart';
import '../../shared/widgets/brand_mark.dart';

/// Shell shared by the sign-in, sign-up and recovery screens (website `AuthShell`): logo, title,
/// intro, the form, an optional security note and the list of preview states used to review the
/// error and result layouts. Nothing typed on these screens is read, stored or sent.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.intro,
    required this.child,
    this.states = const [],
    this.currentState = 'default',
    this.note,
  });

  final String title;
  final String intro;
  final Widget child;

  /// Preview states as (id, label). The current one is the `preview` query value.
  final List<(String id, String label)> states;
  final String currentState;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.pageGutter),
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => context.go('/'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: BrandLogo(),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(intro, style: TextStyle(color: t.muted)),
            const SizedBox(height: AppTokens.space5),
            child,
            if (note != null) ...[
              const SizedBox(height: AppTokens.space4),
              Text(
                note!,
                style: TextStyle(fontSize: AppTokens.textMeta, color: t.muted),
              ),
            ],
            if (states.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space5),
              Material(
                color: t.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  side: BorderSide(color: t.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text(
                      'Preview states',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('For reviewing the designed layouts'),
                    childrenPadding: const EdgeInsets.all(AppTokens.space3),
                    children: [
                      Wrap(
                        spacing: AppTokens.space2,
                        runSpacing: AppTokens.space2,
                        children: [
                          for (final (id, label) in states)
                            ChoiceChip(
                              label: Text(label),
                              selected: id == currentState,
                              onSelected: (_) {
                                final path = GoRouterState.of(context).uri.path;
                                context.replace(
                                  id == 'default' ? path : '$path?preview=$id',
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error or notice banner above a form.
class FormBanner extends StatelessWidget {
  const FormBanner({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFFA3205C);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.space4),
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8F5),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.triangleAlert, size: 20, color: fg),
            const SizedBox(width: AppTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  Text(message, style: const TextStyle(color: fg)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result panel used by the confirmation, expired-link and success layouts.
class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.icon = LucideIcons.circleCheck,
  });

  final String title;
  final String message;
  final List<Widget> actions;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: t.green, size: 28),
          const SizedBox(height: AppTokens.space2),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(color: t.muted)),
          const SizedBox(height: AppTokens.space4),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: actions,
          ),
        ],
      ),
    );
  }
}

const _demoHint =
    'Demo only — don’t enter a real password; this page never receives it.';

/// Labelled text field. Its value is never read: the demo forms do not collect anything.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.error,
    this.keyboardType,
    this.autofillHints,
  });

  final String label;
  final String? hint;
  final String? error;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space4),
    child: TextField(
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

const _rules = <(String, bool Function(String))>[
  ('At least 12 characters', _long),
  ('Upper and lower case letters', _cases),
  ('A number or symbol', _symbol),
];
bool _long(String v) => v.length >= 12;
bool _cases(String v) =>
    RegExp('[a-z]').hasMatch(v) && RegExp('[A-Z]').hasMatch(v);
bool _symbol(String v) => RegExp(r'[\d\W_]').hasMatch(v);

/// Password field with a show/hide button, the demo hint and optional live requirements.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.label,
    this.hint = true,
    this.error,
    this.showRequirements = false,
  });

  final String label;
  final bool hint;
  final String? error;
  final bool showRequirements;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _visible = false;
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            obscureText: !_visible,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: widget.showRequirements
                ? (v) => setState(() => _typed = v)
                : null,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: widget.error,
              helperText: widget.hint ? _demoHint : null,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _visible ? 'Hide password' : 'Show password',
                icon: Icon(
                  _visible ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                ),
                onPressed: () => setState(() => _visible = !_visible),
              ),
            ),
          ),
          if (widget.showRequirements) ...[
            const SizedBox(height: AppTokens.space2),
            Semantics(
              label: 'Password requirements',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (text, test) in _rules)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            test(_typed)
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            size: 14,
                            color: test(_typed) ? t.green : t.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$text${test(_typed) ? ' (met)' : ' (not met yet)'}',
                              style: TextStyle(
                                fontSize: AppTokens.textMeta,
                                color: test(_typed) ? t.green : t.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens the "nothing is sent" explanation used when a demo form is submitted.
Future<void> showDemoSubmitSheet(
  BuildContext context, {
  required String title,
  required String body,
  List<Widget> actions = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        0,
        AppTokens.space5,
        AppTokens.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTokens.space2),
          Text(body),
          const SizedBox(height: AppTokens.space4),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ...actions,
            ],
          ),
        ],
      ),
    ),
  );
}
