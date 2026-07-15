import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_controller.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/daily/presentation/question_screen.dart';
import '../../features/daily/presentation/verse_reader.dart';
import '../../features/duas/presentation/dua_list_screen.dart';
import '../../features/gratitude/presentation/gratitude_screen.dart';
import '../../features/home/domain/home_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/pairing/domain/pairing_providers.dart';
import '../../features/pairing/presentation/pair_screen.dart';
import '../../features/prayer_log/presentation/prayer_log_screen.dart';
import '../motion/motion.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final couple = ref.read(currentCoupleProvider);

      final path = state.uri.path;
      final signedIn = session.asData?.value != null;

      final isSplash = path == '/splash';
      final isAuthRoute = path.startsWith('/auth');
      final isPair = path == '/pair';
      final isOnboarding = path == '/onboarding';

      // Still resolving auth: stay on splash.
      if (!session.hasValue) {
        return isSplash ? null : '/splash';
      }

      if (!signedIn) {
        return isAuthRoute ? null : '/auth/sign-in';
      }

      // Wait for the own profile to have a resolved value before deciding
      // whether onboarding is needed — otherwise the user briefly sees the
      // wrong screen.
      final profile = ref.read(ownProfileProvider);
      if (!profile.hasValue) {
        return isSplash ? null : '/splash';
      }

      if (ref.read(needsOnboardingProvider)) {
        return isOnboarding ? null : '/onboarding';
      }

      if (isOnboarding) return '/pair';

      // Wait for couple stream to have a resolved value before deciding
      // between /pair and /home — otherwise the user briefly sees /pair.
      if (!couple.hasValue) {
        return isSplash ? null : '/splash';
      }

      final paired = couple.value != null;

      if (!paired) {
        return isPair ? null : '/pair';
      }

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
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/pair',
        builder: (_, _) => const PairScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'prayer',
            builder: (_, _) => const PrayerLogScreen(),
          ),
          GoRoute(
            path: 'verse',
            builder: (_, _) => const VerseReaderScreen(),
          ),
          GoRoute(
            path: 'question',
            builder: (_, _) => const QuestionScreen(),
          ),
          GoRoute(
            path: 'gratitude',
            builder: (_, _) => const GratitudeScreen(),
          ),
          GoRoute(
            path: 'duas',
            builder: (_, _) => const DuaListScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Splash: the calligraphy fades and slightly rises. A hero tag ties the
/// mark to the sign-in screen so it flies across the transition.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SakMotion.slow,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anim =
        CurvedAnimation(parent: _controller, curve: SakMotion.enter);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, child) => Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - anim.value) * -8),
              child: child,
            ),
          ),
          child: Hero(
            tag: 'sakinah-mark',
            flightShuttleBuilder: (_, _, _, _, _) => Material(
              type: MaterialType.transparency,
              child: Text(
                'سَكِينَة',
                style: SakTypography.arabicText(
                  fontSize: 42,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                'سَكِينَة',
                style: SakTypography.arabicText(
                  fontSize: 42,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(SakSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 32, color: theme.colorScheme.error),
              const SizedBox(height: SakSpace.md),
              Text(
                "Something went wrong",
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: SakSpace.xs),
              Text(
                error?.toString() ?? 'Unknown route error',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SakSpace.xl),
              TextButton(
                onPressed: () => GoRouter.of(context).go('/splash'),
                child: const Text('Back to start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bridges Riverpod async changes to go_router's listenable.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authSessionProvider, (_, _) => notifyListeners());
    _ref.listen(ownProfileProvider, (_, _) => notifyListeners());
    _ref.listen(currentCoupleProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}
