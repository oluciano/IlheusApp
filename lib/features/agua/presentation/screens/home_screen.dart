import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/presentation/providers/providers.dart';
import 'package:ilheus_app/shared/widgets/empty_state.dart';

final mesesSalvosProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(aberturaMesRepositoryProvider);
  if (repository == null) return [];
  return repository.listarTodosMeses();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesesAsync = ref.watch(mesesSalvosProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Condomínio Ilhéu'),
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(mesesSalvosProvider),
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Grid de Métricas (Animated)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _StaggeredEntrance(
                controller: _entranceController,
                index: 0,
                child: _buildMetricGrid(context, isDesktop),
              ),
            ),
          ),

          // Gráfico de Consumo (Animated)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _StaggeredEntrance(
                controller: _entranceController,
                index: 1,
                child: RepaintBoundary(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Consumo de Água (m³)', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 24),
                          const SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: _ConsumptionChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Histórico de Meses
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _StaggeredEntrance(
                controller: _entranceController,
                index: 2,
                child: Text(
                  'Gestão de Meses',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          mesesAsync.when(
            data: (meses) {
              if (meses.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    message: 'Nenhum mês cadastrado',
                    icon: Icons.calendar_month_outlined,
                    subtitle: 'Toque em "Novo Mês" para começar',
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final mesAno = meses[i];
                    return _StaggeredEntrance(
                      controller: _entranceController,
                      index: 3 + i,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Hero(
                              tag: 'calendar-$mesAno',
                              child: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.calendar_today,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 18,
                                ),
                              ),
                            ),
                            title: Text(_nomeMesFormatado(mesAno), style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () async {
                              try {
                                await ref
                                    .read(aberturaMesFormProvider.notifier)
                                    .abrirMesExistente(mesAno);
                                if (context.mounted) {
                                  context.go('/abertura-mes');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro ao abrir mês: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: meses.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Erro: $e'))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.invalidate(aberturaMesFormProvider);
          context.go('/abertura-mes');
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Mês'),
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 3 : 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isDesktop ? 2.5 : 3.5,
      children: [
        _MetricCard(title: 'Faturas em Aberto', value: '4', icon: Icons.receipt_long, color: Colors.orange, onTap: () {}),
        _MetricCard(title: 'Próxima Reserva', value: 'Quiosque B', icon: Icons.event, color: Colors.green, onTap: () => context.go('/reservas')),
        _MetricCard(title: 'Avisos Novos', value: '2', icon: Icons.campaign, color: Colors.purple, onTap: () => context.go('/avisos')),
      ],
    );
  }

  String _nomeMesFormatado(String mesAno) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final parts = mesAno.split('/');
    if (parts.length != 2) return mesAno;
    final mes = int.tryParse(parts[0]);
    if (mes == null || mes < 1 || mes > 12) return mesAno;
    return '${meses[mes - 1]} de ${parts[1]}';
  }
}

class _StaggeredEntrance extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggeredEntrance({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        (0.1 * index).clamp(0.0, 0.5),
        (0.1 * index + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsumptionChart extends StatelessWidget {
  const _ConsumptionChart();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      painter: _ChartPainter(
        data: [8, 12, 10, 15, 11, 14],
        lineColor: color,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _ChartPainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double widthBetweenPoints = size.width / (data.length - 1);
    final double maxData = data.reduce(math.max);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      double x = i * widthBetweenPoints;
      double y = size.height - (data[i] / maxData * size.height);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
