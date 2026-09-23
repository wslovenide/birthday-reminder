import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/month_overview_screen.dart';
import '../features/dashboard/presentation/person_detail_screen.dart';
import '../features/dashboard/presentation/person_edit_screen.dart';
import '../features/dashboard/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/person/new',
        builder: (context, state) => const PersonEditScreen(),
      ),
      GoRoute(
        path: '/person/:id',
        builder: (context, state) => PersonDetailScreen(
          personId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => PersonEditScreen(
              personId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/months',
        builder: (context, state) => const MonthOverviewScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(child: Text('找不到：${state.uri}')),
    ),
  );
});
