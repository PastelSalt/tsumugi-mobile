import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/workspace_store.dart';
import '../../core/state/dev_tools.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/filters.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/states.dart';

class _Prefs {
  const _Prefs({
    this.name = 'Demo user',
    this.email = 'demo@example.com',
    this.week = 'monday',
    this.density = 'comfortable',
    this.motion = 'system',
    this.reminders = true,
  });

  final String name;
  final String email;
  final String week;
  final String density;
  final String motion;
  final bool reminders;

  _Prefs copyWith({
    String? name,
    String? email,
    String? week,
    String? density,
    String? motion,
    bool? reminders,
  }) => _Prefs(
    name: name ?? this.name,
    email: email ?? this.email,
    week: week ?? this.week,
    density: density ?? this.density,
    motion: motion ?? this.motion,
    reminders: reminders ?? this.reminders,
  );

  @override
  bool operator ==(Object other) =>
      other is _Prefs &&
      other.name == name &&
      other.email == email &&
      other.week == week &&
      other.density == density &&
      other.motion == motion &&
      other.reminders == reminders;

  @override
  int get hashCode =>
      Object.hash(name, email, week, density, motion, reminders);
}

/// Account: profile and preferences (website `AccountPage`, PLAN-A-04K). A preview only: edits
/// stay on screen, an "Edited" badge and Reset appear, and nothing is saved.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  static const _defaults = _Prefs();
  var _form = _defaults;
  late final _name = TextEditingController(text: _defaults.name);
  late final _email = TextEditingController(text: _defaults.email);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() => _form = _defaults);
    _name.text = _defaults.name;
    _email.text = _defaults.email;
  }

  Widget _card(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space3),
    child: Material(
      color: context.tokens.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(color: context.tokens.line),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: AppTokens.space3),
            ...children,
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final edited = _form != _defaults;
    final dev = ref.watch(devToolsProvider);
    final sessionCount = ref.watch(sessionProvider).count;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.pageGutter),
      children: [
        const PageHeader(
          title: 'Account',
          description: 'Profile and preferences for your individual workspace.',
        ),
        StateGate(
          empty: const EmptyState(title: 'Nothing to show'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.space3),
                margin: const EdgeInsets.only(bottom: AppTokens.space3),
                decoration: BoxDecoration(
                  color: t.blueSoft,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Wrap(
                  spacing: AppTokens.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Changes here are a preview. Nothing is saved yet.',
                    ),
                    if (edited) ...[
                      const TonePill(label: 'Edited', tone: StatusTone.info),
                      TextButton(onPressed: _reset, child: const Text('Reset')),
                    ],
                  ],
                ),
              ),
              _card('Profile', [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _form = _form.copyWith(name: v)),
                ),
                const SizedBox(height: AppTokens.space3),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _form = _form.copyWith(email: v)),
                ),
              ]),
              _card('Preferences', [
                FilterField(
                  label: 'Week starts on',
                  value: _form.week,
                  options: const [('monday', 'Monday'), ('sunday', 'Sunday')],
                  onChanged: (v) =>
                      setState(() => _form = _form.copyWith(week: v)),
                ),
                FilterField(
                  label: 'Density',
                  value: _form.density,
                  options: const [
                    ('comfortable', 'Comfortable'),
                    ('compact', 'Compact'),
                  ],
                  onChanged: (v) =>
                      setState(() => _form = _form.copyWith(density: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remind me about tasks due today'),
                  value: _form.reminders,
                  onChanged: (v) =>
                      setState(() => _form = _form.copyWith(reminders: v)),
                ),
              ]),
              _card('Appearance', [
                FilterField(
                  label: 'Motion',
                  value: _form.motion,
                  options: const [
                    ('system', 'Follow my device'),
                    ('reduced', 'Reduce motion'),
                  ],
                  onChanged: (v) =>
                      setState(() => _form = _form.copyWith(motion: v)),
                ),
              ]),
              _card('Privacy', [
                const Text(
                  'This demo stores nothing. Read the privacy policy for how the real service will handle your data.',
                ),
                const SizedBox(height: AppTokens.space2),
                TextButton(
                  onPressed: () => context.push('/legal/privacy-policy'),
                  child: const Text('Privacy Policy'),
                ),
              ]),
              _card('Developer', [
                const Text(
                  'Tools for reviewing designed states. Most people never need these.',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show developer tools'),
                  value: dev,
                  onChanged: (v) => ref.read(devToolsProvider.notifier).set(v),
                ),
                OutlinedButton(
                  onPressed: sessionCount == 0
                      ? null
                      : () => ref.read(sessionProvider.notifier).reset(),
                  child: Text(
                    'Reset session data${sessionCount == 0 ? '' : ' ($sessionCount)'}',
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
