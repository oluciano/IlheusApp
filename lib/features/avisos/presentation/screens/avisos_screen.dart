import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AvisosScreen extends StatelessWidget {
  const AvisosScreen({super.key});

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
        title: const Text('Avisos'),
      ),
      body: const _AvisosList(),
    );
  }
}

class _AvisosList extends StatelessWidget {
  const _AvisosList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _avisosMock.length,
        itemBuilder: (context, index) {
          final aviso = _avisosMock[index];
          return _AvisoCard(aviso: aviso);
        },
      ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  final _AvisoMock aviso;

  const _AvisoCard({required this.aviso});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  aviso.tipo.icon,
                  color: aviso.tipo.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aviso.titulo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: aviso.tipo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    aviso.tipo.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: aviso.tipo.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              aviso.descricao,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatarData(aviso.data),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
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
    return '${data.day} de ${meses[data.month - 1]} de ${data.year}';
  }
}

enum _TipoAviso {
  info(Icons.info_outline, Colors.blue, 'Informativo'),
  alerta(Icons.warning_amber_outlined, Colors.orange, 'Alerta'),
  urgencia(Icons.error_outline, Colors.red, 'Urgente'),
  manutencao(Icons.build_outlined, Colors.purple, 'Manutenção');

  final IconData icon;
  final Color color;
  final String label;
  const _TipoAviso(this.icon, this.color, this.label);
}

class _AvisoMock {
  final String titulo;
  final String descricao;
  final DateTime data;
  final _TipoAviso tipo;

  _AvisoMock({
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.tipo,
  });
}

final _avisosMock = [
  _AvisoMock(
    titulo: 'Manutenção do Hidrômetro Geral',
    descricao:
        'A CORSAN realizará manutenção no hidrômetro geral no dia 15/04. '
        'O abastecimento poderá ser interrompido por até 2 horas.',
    data: DateTime(2026, 4, 10),
    tipo: _TipoAviso.manutencao,
  ),
  _AvisoMock(
    titulo: 'Reajuste do Condomínio',
    descricao:
        'O valor do condomínio será reajustado em 5% a partir de Maio/2026, '
        'conforme aprovado em assembleia.',
    data: DateTime(2026, 4, 8),
    tipo: _TipoAviso.info,
  ),
  _AvisoMock(
    titulo: 'Quiosque — Uso Restrito',
    descricao:
        'O uso do quiosque nos finais de semana requer reserva prévia. '
        'Procure o administrador para agendar.',
    data: DateTime(2026, 4, 5),
    tipo: _TipoAviso.alerta,
  ),
  _AvisoMock(
    titulo: 'Vazamento na Casa 14',
    descricao:
        'Foi detectado um vazamento na ligação da Casa 14. '
        'O morador foi notificado para providenciar reparo.',
    data: DateTime(2026, 4, 3),
    tipo: _TipoAviso.urgencia,
  ),
  _AvisoMock(
    titulo: 'Assembleia Geral',
    descricao:
        'Assembleia geral marcada para 20/04 às 19h. '
        'Pauta: prestação de contas e eleição do novo conselho.',
    data: DateTime(2026, 4, 1),
    tipo: _TipoAviso.info,
  ),
];
