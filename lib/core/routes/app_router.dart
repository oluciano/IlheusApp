import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/presentation/screens/abertura_mes_screen.dart';
import 'package:ilheus_app/features/agua/presentation/screens/home_screen.dart';
import 'package:ilheus_app/features/avisos/presentation/screens/avisos_screen.dart';
import 'package:ilheus_app/features/reservas/presentation/screens/reservas_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
    ShellRoute(
      builder: (_, __, child) => child,
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/abertura-mes',
          builder: (_, __) => const AberturaMesScreen(),
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
