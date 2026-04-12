import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/presentation/providers/providers.dart';
import 'package:ilheus_app/features/agua/presentation/widgets/month_year_picker.dart';
import 'package:ilheus_app/shared/widgets/empty_state.dart';

import 'package:ilheus_app/features/agua/domain/models/home_month_overview.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';

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
            title: const Text('Condomínio Ilhéus'),
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(mesesSalvosProvider),
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Grid de Métricas (Animated Tiles)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: mesesAsync.when(
              data: (meses) => _buildMetricGrid(context, isDesktop, meses),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ),

          // Histórico de Meses
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _StaggeredEntrance(
                controller: _entranceController,
                index: 1,
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
                    final overview = meses[i];
                    final mesAno = overview.mesAno;
                    
                    return _StaggeredEntrance(
                      controller: _entranceController,
                      index: 2 + i,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
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
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Hero(
                                        tag: 'calendar-$mesAno',
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.calendar_today,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _nomeMesFormatado(mesAno),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            _buildStatusBadge(context, overview),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                                    ],
                                  ),
                                  if (!overview.isFechado) ...[
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: overview.progresso,
                                        minHeight: 6,
                                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                        color: overview.isCompleto ? Colors.green : theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${overview.casasLidas}/${overview.totalCasas} casas lidas',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        if (overview.isCompleto)
                                          const Text(
                                            'Pronto para fechar',
                                            style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
        onPressed: () async {
          ref.read(aberturaMesFormProvider.notifier).reset();
          
          String? sugestao;
          final meses = mesesAsync.asData?.value;
          if (meses != null && meses.isNotEmpty) {
            // Pega o mais recente (já está ordenado)
            final ultimo = meses.first.mesAno;
            final partes = ultimo.split('/');
            int mes = int.parse(partes[0]);
            int ano = int.parse(partes[1]);
            if (mes == 12) {
              mes = 1;
              ano++;
            } else {
              mes++;
            }
            sugestao = '${mes.toString().padLeft(2, '0')}/$ano';
          }

          final mesAno = await MonthYearPickerSheet.show(context, initialMesAno: sugestao);
          if (mesAno == null || !context.mounted) return;

          final jaExiste = await ref
              .read(aberturaMesFormProvider.notifier)
              .mesJaCadastrado(mesAno);

          if (!context.mounted) return;

          if (jaExiste) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'O mês $mesAno já está cadastrado. '
                  'Selecione-o na lista para editar.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            await ref
                .read(aberturaMesFormProvider.notifier)
                .abrirNovoMes(mesAno);
            if (context.mounted) {
              context.go('/abertura-mes');
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Mês'),
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, bool isDesktop, List<HomeMonthOverview> meses) {
    final abertos = meses.where((m) => !m.isFechado).length;

    return SliverGrid.count(
      crossAxisCount: isDesktop ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _StaggeredEntrance(
          controller: _entranceController,
          index: 0,
          child: _MetricTile(
            title: 'Meses em Aberto',
            value: abertos.toString(),
            icon: Icons.receipt_long,
            color: Colors.orange,
            onTap: () {},
          ),
        ),
        _StaggeredEntrance(
          controller: _entranceController,
          index: 1,
          child: _MetricTile(
            title: 'Reservas',
            value: 'Quiosque B',
            icon: Icons.event,
            color: Colors.green,
            onTap: () => context.go('/reservas'),
          ),
        ),
        _StaggeredEntrance(
          controller: _entranceController,
          index: 2,
          child: _MetricTile(
            title: 'Avisos',
            value: '2',
            icon: Icons.campaign,
            color: Colors.purple,
            onTap: () => context.go('/avisos'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, HomeMonthOverview overview) {
    String text;
    Color color;
    IconData icon;

    if (overview.isFechado) {
      text = 'Fechado';
      color = Colors.green;
      icon = Icons.verified;
    } else if (overview.isCompleto) {
      text = 'Leitura Completa';
      color = Colors.blue;
      icon = Icons.fact_check;
    } else if (overview.casasLidas > 0) {
      text = 'Em Leitura';
      color = Colors.orange;
      icon = Icons.pending;
    } else {
      text = 'Rascunho';
      color = Colors.grey;
      icon = Icons.edit_document;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: value.length > 8 ? 14 : 18,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
