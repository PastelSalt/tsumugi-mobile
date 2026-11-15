import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/help/help_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/library/doc_reader_screen.dart';
import '../features/library/library_screen.dart';
import '../features/project/project_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/search/search_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/quickadd/quick_add_sheet.dart';
import 'placeholder_screen.dart';
import 'shell/app_shell.dart';
import 'shell/fade_through_branches.dart';

/// A pushed page outside the bottom-bar tabs: app bar with a back button and the screen below it.
Widget _page(String title, Widget body) =>
    SubPageScaffold(title: title, child: body);

/// Route table from docs/PLAN-FLUTTER-MOBILE.md section 6. View, filter and selection state
/// travels in query parameters (view, status, project, mode, month, day, select, rev, preview).
GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(preview: state.uri.queryParameters['preview']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterScreen(preview: state.uri.queryParameters['preview']),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            ForgotPasswordScreen(preview: state.uri.queryParameters['preview']),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(preview: state.uri.queryParameters['preview']),
      ),
      // Launcher shortcut "Add task" (tsumugi:///add): open Home with Quick add on top.
      GoRoute(path: '/add', builder: (context, state) => const _OpenQuickAdd()),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => _page(
          'Insights',
          InsightsScreen(params: state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => _page('Account', const AccountScreen()),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => _page('Help', const HelpScreen()),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/legal/:doc',
        builder: (context, state) =>
            _page('Legal', LegalScreen(slug: state.pathParameters['doc']!)),
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughBranches(
              currentIndex: shell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) =>
                    ProjectsScreen(params: state.uri.queryParameters),
                routes: [
                  GoRoute(
                    path: ':projectId',
                    builder: (context, state) => ProjectScreen(
                      projectId: state.pathParameters['projectId']!,
                      params: state.uri.queryParameters,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) =>
                    TasksScreen(params: state.uri.queryParameters),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) =>
                    LibraryScreen(params: state.uri.queryParameters),
                routes: [
                  GoRoute(
                    path: 'doc/:fileId',
                    builder: (context, state) => DocReaderScreen(
                      fileId: state.pathParameters['fileId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const SubPageScaffold(
      title: 'Page not found',
      child: PlaceholderScreen(
        title: 'Page not found',
        description: 'That page does not exist.',
      ),
    ),
  );
}

/// Goes to Home and opens Quick add on top of it, then is gone.
class _OpenQuickAdd extends StatefulWidget {
  const _OpenQuickAdd();

  @override
  State<_OpenQuickAdd> createState() => _OpenQuickAddState();
}

class _OpenQuickAddState extends State<_OpenQuickAdd> {
  @override
  void initState() {
    super.initState();
    final router = GoRouter.of(context);
    final overlayContext = Navigator.of(context, rootNavigator: true).context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go('/home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlayContext.mounted) showQuickAddSheet(overlayContext);
      });
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
