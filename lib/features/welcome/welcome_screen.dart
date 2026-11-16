import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/docs/legal_meta.dart';
import '../../core/net/auth_state.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/brand_mark.dart';

// Sample thread from the website landing page. All content is illustrative.
const _stages = [
  (
    'Objective',
    'Ship a welcoming first chapter',
    ['Project Garden', 'Creative'],
    'The reason the work exists at all.',
    'It becomes requirements you can actually check.',
  ),
  (
    'Requirement',
    'REQ-001 · Opening scene sets the tone',
    ['In progress', 'Unverified'],
    'It answers the objective in a testable way.',
    'It becomes a milestone and the tasks that deliver it.',
  ),
  (
    'Milestone',
    'Chapter one review',
    ['Due 13 Nov', 'High priority'],
    'A checkpoint where the requirement is judged.',
    'It breaks down into tasks with dates.',
  ),
  (
    'Task',
    'Review opening scene notes',
    ['In progress', 'High priority'],
    'The next piece of work that moves the milestone.',
    'It produces recorded revisions.',
  ),
  (
    'Revision',
    'Opening brief · v3 → v4',
    ['Pending review', 'Linked to the task'],
    'A recorded change you can trace back to its task.',
    'It rolls up into a deliverable.',
  ),
  (
    'Deliverable',
    'Chapter one script',
    ['Delivered', 'Satisfies REQ-001'],
    'What the work became.',
    'The loop closes: the objective is met, with proof.',
  ),
];

const _worlds = [
  (
    LucideIcons.code,
    'Software',
    'Shape requirements into reliable releases.',
    'A tagged release you can trace to its requirements',
  ),
  (
    LucideIcons.bookOpen,
    'Creative',
    'Carry ideas from worldbuilding to finished scenes.',
    'A finished chapter with its drafts on record',
  ),
  (
    LucideIcons.flaskConical,
    'Research',
    'Connect questions, methods, findings, and deliverables.',
    'A report whose claims point to evidence',
  ),
  (
    LucideIcons.audioWaveform,
    'Multimedia',
    'Keep assets, reviews, and versions moving together.',
    'A final cut with every review attached',
  ),
];

/// Welcome (the short mobile version of the website landing page): tagline, the traceability
/// thread, the kinds of making it suits, and the way into the demo.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A saved session that still works skips Welcome (the check runs once at launch).
    ref.listen(authProvider, (_, next) {
      if (next.isSignedIn) context.go('/home');
    });
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.pageGutter),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: BrandLogo()),
            ),
            const SizedBox(height: AppTokens.space5),
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: t.pink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Creative & technical production management',
                    style: TextStyle(
                      fontSize: AppTokens.textMeta,
                      color: t.pink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Weaving ideas into '),
                    TextSpan(
                      text: 'finished work.',
                      style: TextStyle(color: t.pink),
                    ),
                  ],
                ),
                style: text.headlineMedium?.copyWith(fontSize: 38, height: 1.1),
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            FilledButton(
              onPressed: () {
                // The demo: bundled sample data, no network, nothing stored. A permanent feature.
                ref.read(authProvider.notifier).enterDemo();
                context.go('/home');
              },
              child: const Text('Continue as demo user'),
            ),
            const SizedBox(height: AppTokens.space2),
            OutlinedButton(
              onPressed: () => context.go('/sign-in'),
              child: const Text('Log in'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.go('/sign-up'),
                child: const Text('New to Tsumugi? Create account'),
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            Text(
              'The Tsumugi difference',
              style: TextStyle(
                fontSize: AppTokens.textMeta,
                color: t.pink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: Text(
                'See the why behind the work.',
                style: text.titleLarge,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            const _ThreadPager(),
            const SizedBox(height: AppTokens.space5),
            Text(
              'Made for different kinds of making',
              style: TextStyle(
                fontSize: AppTokens.textMeta,
                color: t.pink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: Text('One thread. Many worlds.', style: text.titleLarge),
            ),
            const SizedBox(height: AppTokens.space3),
            for (final (icon, title, body, out) in _worlds)
              Container(
                margin: const EdgeInsets.only(bottom: AppTokens.space2),
                padding: const EdgeInsets.all(AppTokens.space3),
                decoration: BoxDecoration(
                  color: t.paper,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: t.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: t.ink),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(body),
                          const SizedBox(height: 2),
                          Text(
                            out,
                            style: TextStyle(
                              fontSize: AppTokens.textMeta,
                              color: t.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.space4),
            Wrap(
              children: [
                for (final (slug, label) in legalLinks)
                  TextButton(
                    onPressed: () => context.push('/legal/$slug'),
                    child: Text(label),
                  ),
              ],
            ),
            Text(
              'A frontend-only demo. Nothing is saved or sent.',
              style: TextStyle(fontSize: AppTokens.textMeta, color: t.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The six-step thread as a swipeable pager with a step indicator.
class _ThreadPager extends StatefulWidget {
  const _ThreadPager();

  @override
  State<_ThreadPager> createState() => _ThreadPagerState();
}

class _ThreadPagerState extends State<_ThreadPager> {
  final _controller = ScrollController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final extent = _cardWidth + AppTokens.space2;
      final page = (_controller.offset / extent).round().clamp(
        0,
        _stages.length - 1,
      );
      if (page != _page) setState(() => _page = page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _cardWidth = 280;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    _cardWidth =
        (MediaQuery.sizeOf(context).width - 2 * AppTokens.pageGutter) * 0.88;
    return Column(
      children: [
        SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _stages.length; i++)
                  Container(
                    width: _cardWidth,
                    margin: const EdgeInsets.only(right: AppTokens.space2),
                    padding: const EdgeInsets.all(AppTokens.space4),
                    decoration: BoxDecoration(
                      color: t.paper,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(color: t.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1} of ${_stages.length} · ${_stages[i].$1}',
                          style: TextStyle(
                            fontSize: AppTokens.textMeta,
                            color: t.pink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stages[i].$2,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stages[i].$3.join(' · '),
                          style: TextStyle(
                            fontSize: AppTokens.textMeta,
                            color: t.muted,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppTokens.space3),
                        const Text(
                          'Why it exists',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(_stages[i].$4),
                        const SizedBox(height: 6),
                        const Text(
                          'What it becomes',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(_stages[i].$5),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _stages.length; i++)
              Container(
                width: i == _page ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? t.pink : t.lineStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
