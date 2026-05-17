import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/landing/landing_screen.dart';
import '../../../features/onboarding/onboarding_providers.dart';
import '../../../features/onboarding/onboarding_screen.dart';
import '../../features/landing/widgets/conversation_stage.dart';
import 'route_screens.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// The app-wide [GoRouter].
///
/// Holds the onboarding redirect, the routes for every reachable screen,
/// and a navigator key that other parts of the app can grab when they
/// need imperative access (e.g. the notification handler in Phase 08).
///
/// `keepAlive: true` because the router holds a navigator and route
/// stack. Disposing and recreating would lose the user's place.
@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  // A single navigator key so deep-link handlers can reach the router
  // from outside a `BuildContext` (Phase 08 uses this).
  final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>(debugLabel: 'AppNavigator');

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.landing,
    debugLogDiagnostics: false,

    // The redirect is consulted on every navigation. It watches the
    // onboarding state and bounces between /onboarding and / as needed.
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<bool> onboarded =
      ref.read(onboardingCompletedProvider);
      // While onboarding state is still resolving, stay where the
      // user is — the splash screen behind go_router renders. A
      // refresh fires once the future resolves (see refreshListenable).
      final bool? done = onboarded.valueOrNull;
      if (done == null) return null;

      final bool atOnboarding =
          state.matchedLocation == AppRoutes.onboarding;

      if (!done && !atOnboarding) {
        return AppRoutes.onboarding;
      }
      if (done && atOnboarding) {
        return AppRoutes.landing;
      }
      return null; // no redirect
    },

    // When the onboarding state changes, re-run redirect.
    refreshListenable: _OnboardingRefreshListenable(ref),

    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.landing,
        name: 'landing',
        builder: (BuildContext context, GoRouterState state) =>
        const _LandingRouteShell(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return OnboardingScreen(
            onGetStarted: () {
              // The redirect will route us to / once the flag flips.
              // No explicit navigation needed.
            },
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.confirm}/:planItemId',
        name: 'confirm',
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['planItemId']!;
          return ConfirmRouteScreen(planItemId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.plan}/:rootId',
        name: 'plan',
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['rootId']!;
          return PlanRouteScreen(rootId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.leftover}/:bucket',
        name: 'leftover',
        builder: (BuildContext context, GoRouterState state) {
          final int bucket =
              int.tryParse(state.pathParameters['bucket'] ?? '') ??
                  -1;
          return LeftoverRouteScreen(dayBucket: bucket);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) =>
        const SettingsRouteScreen(),
      ),
    ],

    // A small fallback when a deep link references something we don't
    // know about. Surface a clean Not Found with a way back home.
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('We couldn\'t open ${state.uri.path}.'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      GoRouter.of(context).go(AppRoutes.landing),
                  child: const Text('Back to plan'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// A [ChangeNotifier] that fires whenever [onboardingCompletedProvider]
/// changes value — feeds [GoRouter.refreshListenable] so the redirect
/// re-evaluates.
class _OnboardingRefreshListenable extends ChangeNotifier {
  _OnboardingRefreshListenable(this._ref) {
    _sub = _ref.listen<AsyncValue<bool>>(
      onboardingCompletedProvider,
          (AsyncValue<bool>? prev, AsyncValue<bool> curr) {
        if (prev?.valueOrNull != curr.valueOrNull) {
          notifyListeners();
        }
      },
    );
  }

  // ignore: unused_field
  final Ref _ref;
  late final ProviderSubscription<AsyncValue<bool>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// The landing screen, wired with route navigation callbacks instead
/// of snackbars. Pulled into its own widget so the router file stays
/// short.
class _LandingRouteShell extends ConsumerWidget {
  const _LandingRouteShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = GoRouter.of(context);
    return LandingScreen(
      onOpenPlanItem: (item) {
        router.pushNamed(
          'confirm',
          pathParameters: <String, String>{'planItemId': item.id},
        );
      },
      onOpenSettings: () => router.pushNamed('settings'),
      onExpandIsland: () {
        ref.read(conversationStageProvider.notifier).expand();
      },
      onVoiceCapture: () {
        // Voice capture is screen-local — Phase 07 wires the recorder.
        // For now we surface a marker so testers know it registered.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice capture — Phase 07')),
        );
      },
    );
  }
}