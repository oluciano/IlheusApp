import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReservasScreen extends StatelessWidget {
  const ReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
          tooltip: 'Voltar',
        ),
        title: const Text('Reservas'),
      ),
      body: const _ReservasList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva de quiuiosque em desenvolvimento.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Reserva'),
      ),
    );
  }
}

class _ReservasList extends StatelessWidget {
  const _ReservasList();

  @override
  Widget build(BuildContext context) {
    final reservas = _reservasMock;

    if (reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline.withValues(
                    alpha: 0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma reserva encontrada',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Nova Reserva" para agendar o quiiosque',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline.withValues(
                          alpha: 0.7,
                        ),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservas.length,
        itemBuilder: (context, index) {
          final reserva = reservas[index];
          return _ReservaCard(reserva: reserva);
        },
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final _ReservaMock reserva;

  const _ReservaCard({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusCor = reserva.status.color;
    final statusIcon = reserva.status.icon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusCor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: statusCor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiosque — ${_formatarData(reserva.data)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solicitado por Casa ${reserva.casaNumero}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(statusIcon, size: 16, color: statusCor),
                  label: Text(
                    reserva.status.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusCor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (reserva.observacao != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reserva.observacao!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    const diasSemana = [
      'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
    ];
    final dia = diasSemana[data.weekday - 1];
    return '$dia, ${data.day} de ${meses[data.month - 1]}';
  }
}

enum _StatusReserva {
  confirmada(Icons.check_circle, Colors.green, 'Confirmada'),
  pendente(Icons.schedule, Colors.orange, 'Pendente');

  final IconData icon;
  final Color color;
  final String label;
  const _StatusReserva(this.icon, this.color, this.label);
}

class _ReservaMock {
  final DateTime data;
  final int casaNumero;
  final _StatusReserva status;
  final String? observacao;

  _ReservaMock({
    required this.data,
    required this.casaNumero,
    required this.status,
    this.observacao,
  });
}

final _reservasMock = [
  _ReservaMock(
    data: DateTime(2026, 4, 12),
    casaNumero: 5,
    status: _StatusReserva.confirmada,
    observacao: 'Churrasco de aniversário — período integral',
  ),
  _ReservaMock(
    data: DateTime(2026, 4, 19),
    casaNumero: 11,
    status: _StatusReserva.pendente,
    observacao: 'Reunião de família — período da tarde',
  ),
  _ReservaMock(
    data: DateTime(2026, 4, 26),
    casaNumero: 3,
    status: _StatusReserva.pendente,
  ),
];
