import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/presentation/screens/agua_screen.dart';
import 'package:ilheus_app/features/avisos/presentation/screens/avisos_screen.dart';
import 'package:ilheus_app/features/reservas/presentation/screens/reservas_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (_, __) => '/agua',
    ),
    ShellRoute(
      builder: (_, __, child) => child,
      routes: [
        GoRoute(
          path: '/agua',
          builder: (_, __) => const AguaScreen(),
        ),
        GoRoute(
          path: '/avisos',
          builder: (_, __) => const AvisosScreen(),
        ),
        GoRoute(
          path: '/reservas',
          builder: (_, __) => const ReservasScreen(),
        ),
      ],
    ),
  ],
);
