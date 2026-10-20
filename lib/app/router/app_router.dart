import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/activities/presentation/activities_screen.dart';
import '../../features/activities/presentation/activity_form_screen.dart';
import '../../features/activities/presentation/activity_detail_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../core/widgets/page_layout.dart';
import '../app.dart';
import '../shell/app_shell.dart';
import '../store/app_store.dart';

String? sessionRedirect(SessionStatus status, String path) {
  final public = path == '/login' || path == '/register';
  if (status == SessionStatus.restoring ||
      status == SessionStatus.restoreFailed) {
    return path == '/loading' ? null : '/loading';
  }
  if (status == SessionStatus.signedOut) return public ? null : '/login';
  return public || path == '/loading' || path == '/' ? '/dashboard' : null;
}

GoRouter createAppRouter(SessionController session) => GoRouter(
  initialLocation: '/dashboard',
  refreshListenable: session,
  redirect: (context, state) =>
      sessionRedirect(session.store.state.status, state.uri.path),
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => context.go('/dashboard'),
        child: const Text('Volver al inicio'),
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: '/loading',
      builder: (context, state) => RestoreSessionScreen(session: session),
    ),
    GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const AuthScreen(isRegistration: true),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) => const ActivitiesScreen(),
        ),
        GoRoute(
          path: '/activities/new',
          builder: (context, state) => ActivityFormScreen(
            projectId: state.uri.queryParameters['projectId'],
          ),
        ),
        GoRoute(
          path: '/activities/:id/edit',
          builder: (context, state) =>
              ActivityFormScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/activities/:id',
          builder: (context, state) =>
              ActivityDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (context, state) =>
              ProjectDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/more',
          builder: (context, state) => PageLayout(
            title: 'Tu espacio',
            children: [
              for (final item in destinations.skip(4))
                Card(
                  child: ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(item.path),
                  ),
                ),
            ],
          ),
        ),
        GoRoute(
          path: '/badges',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: '/rewards',
          builder: (context, state) => const AchievementsScreen(rewards: true),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
