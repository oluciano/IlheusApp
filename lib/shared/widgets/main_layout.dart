import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    
    final String location = GoRouterState.of(context).uri.path;
    final int selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop || isTablet)
            NavigationRail(
              extended: isDesktop,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Icon(Icons.waves, size: 32, color: Color(0xFF1565C0)),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.water_drop_outlined),
                  selectedIcon: Icon(Icons.water_drop),
                  label: Text('Água'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.event_seat_outlined),
                  selectedIcon: Icon(Icons.event_seat),
                  label: Text('Reservas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: Text('Avisos'),
                ),
              ],
            ),
          
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.water_drop_outlined),
                  selectedIcon: Icon(Icons.water_drop),
                  label: 'Água',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_seat_outlined),
                  selectedIcon: Icon(Icons.event_seat),
                  label: 'Reservas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: 'Avisos',
                ),
              ],
            )
          : null,
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/abertura-mes') || location.startsWith('/lancamento-leituras')) return 1;
    if (location.startsWith('/reservas')) return 2;
    if (location.startsWith('/avisos')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick(); // Feedback tátil ao tocar nas abas
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/abertura-mes');
      case 2:
        context.go('/reservas');
      case 3:
        context.go('/avisos');
    }
  }
}
