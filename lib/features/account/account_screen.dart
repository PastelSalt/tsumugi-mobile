import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/workspace_store.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/settings/preferences.dart';
import '../../core/state/dev_tools.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../quickadd/quick_add_sheet.dart';
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
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
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
                      'Profile edits last until you close the app. Nothing is saved.',
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
              _card('Appearance', [
                Semantics(
                  header: true,
                  child: Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                SegmentedToggle(
                  label: 'Theme',
                  value: prefs.themeMode.name,
                  onChanged: (v) => notifier.setThemeMode(
                    ThemeMode.values.firstWhere((m) => m.name == v),
                  ),
                  options: const [
                    ('system', 'System'),
                    ('light', 'Light'),
                    ('dark', 'Dark'),
                  ],
                ),
                const SizedBox(height: AppTokens.space3),
                Semantics(
                  header: true,
                  child: Text(
                    'Text size',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: AppTokens.space2,
                  children: [
                    for (final (scale, label) in textScaleOptions)
                      ChoiceChip(
                        label: Text(label),
                        selected: prefs.textScale == scale,
                        onSelected: (_) => notifier.setTextScale(scale),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  'The quick brown fox jumps over the lazy dog.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce motion'),
                  subtitle: const Text(
                    'Turns animations off. Your device setting is respected too.',
                  ),
                  value: prefs.reduceMotion,
                  onChanged: notifier.setReduceMotion,
                ),
              ]),
              _card('Preferences', [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weeks start on Sunday'),
                  subtitle: const Text('Changes the Calendar grid.'),
                  value: prefs.weekStartsSunday,
                  onChanged: notifier.setWeekStartsSunday,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: AppTokens.minTarget,
                  title: const Text('Show tips again'),
                  subtitle: const Text(
                    'Brings back the hints about swiping tasks and typing in Quick add.',
                  ),
                  trailing: const Icon(LucideIcons.lightbulb, size: 18),
                  onTap: () {
                    ref.read(gestureHintDismissedProvider.notifier).show();
                    ref.read(quickAddTipDismissedProvider.notifier).show();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibration feedback'),
                  subtitle: const Text(
                    'A small tap when you complete a task or add one.',
                  ),
                  value: ref.watch(hapticsEnabledProvider),
                  onChanged: ref.read(hapticsEnabledProvider.notifier).set,
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
                  onPressed: prefs.isDefault ? null : notifier.reset,
                  child: const Text('Reset preferences'),
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
