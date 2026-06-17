import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../views/auth/forgot_password_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/home/home_shell.dart';
import '../views/profile/profile_screen.dart';

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final verified = auth.isEmailVerified;

      final loc = state.matchedLocation;
      final inAuth = loc == '/login' || loc == '/register' || loc == '/forgot-password';

      // Allow access to forgot-password even if not logged in
      if (loc == '/forgot-password') {
        return null;
      }

      if (!loggedIn) {
        return inAuth ? null : '/login';
      }

      if (!verified) {
        return '/login';
      }

      if (inAuth) {
        return '/app';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
