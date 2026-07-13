import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_controller.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pairing/domain/pairing_providers.dart';
import '../../features/pairing/presentation/pair_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final couple = ref.read(currentCoupleProvider);

      final path = state.uri.path;
      final signedIn = session.asData?.value != null;
      final paired = couple.asData?.value != null;

      final isSplash = path == '/splash';
      final isAuthRoute = path.startsWith('/auth');
      final isPair = path == '/pair';

      // Still resolving auth on first frame
      if (session.isLoading && isSplash) return null;

      if (!signedIn) {
        return isAuthRoute ? null : '/auth/sign-in';
      }

      if (!paired) {
        return isPair ? null : '/pair';
      }

      // Signed in + paired: land on home unless already elsewhere
      if (isSplash || isAuthRoute || isPair) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/pair',
        builder: (_, _) => const PairScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Bridges Riverpod async changes to go_router's listenable.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authSessionProvider, (_, _) => notifyListeners());
    _ref.listen(currentCoupleProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}
