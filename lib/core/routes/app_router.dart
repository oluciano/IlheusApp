import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/presentation/screens/abertura_mes_screen.dart';
import 'package:ilheus_app/features/agua/presentation/screens/home_screen.dart';
import 'package:ilheus_app/features/agua/presentation/screens/lancamento_leituras_screen.dart';
import 'package:ilheus_app/features/agua/presentation/screens/fechamento_mensal_screen.dart';
import 'package:ilheus_app/features/avisos/presentation/screens/avisos_screen.dart';
import 'package:ilheus_app/features/reservas/presentation/screens/reservas_screen.dart';
import 'package:ilheus_app/shared/widgets/main_layout.dart';

/// Page transition com slide + fade (mobile UX otimizado).
class _SlideFadePage extends CustomTransitionPage<void> {
  _SlideFadePage({required Widget child})
      : super(
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.04);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final offset = Tween(begin: begin, end: end).animate(curve);
            final fade = Tween(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return SlideTransition(
              position: offset,
              child: FadeTransition(
                opacity: fade,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
    ShellRoute(
      builder: (_, __, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (_, __) => _SlideFadePage(child: const HomeScreen()),
        ),
        GoRoute(
          path: '/abertura-mes',
          pageBuilder: (_, __) =>
              _SlideFadePage(child: const AberturaMesScreen()),
        ),
        GoRoute(
          path: '/lancamento-leituras/:mesAno',
          pageBuilder: (_, state) {
            final mesAno = Uri.decodeComponent(state.pathParameters['mesAno']!);
            return _SlideFadePage(
              child: LancamentoLeiturasScreen(mesAno: mesAno),
            );
          },
        ),
        GoRoute(
          path: '/fechamento-mensal/:mesAno',
          pageBuilder: (_, state) {
            final mesAno = Uri.decodeComponent(state.pathParameters['mesAno']!);
            return _SlideFadePage(
              child: FechamentoMensalScreen(mesAno: mesAno),
            );
          },
        ),
        GoRoute(
          path: '/avisos',
          pageBuilder: (_, __) =>
              _SlideFadePage(child: const AvisosScreen()),
        ),
        GoRoute(
          path: '/reservas',
          pageBuilder: (_, __) =>
              _SlideFadePage(child: const ReservasScreen()),
        ),
      ],
    ),
  ],
);
