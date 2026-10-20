import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dates.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/date_filter.dart';
import '../../../core/widgets/page_layout.dart';
import '../application/dashboard_providers.dart';
import '../data/dashboard.dart';

class StatisticsPanel extends ConsumerStatefulWidget {
  const StatisticsPanel({super.key, required this.timeZone});
  final String timeZone;
  @override
  ConsumerState<StatisticsPanel> createState() => _StatisticsPanelState();
}

class _StatisticsPanelState extends ConsumerState<StatisticsPanel> {
  StatisticsFilter? filter;
  @override
  Widget build(BuildContext context) {
    final today = localToday(widget.timeZone);
    final selected =
        filter ??
        (
          from: civilDate(daysBefore(today, 29)),
          to: civilDate(today),
          categoryId: null,
          interval: 'WEEK',
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tu constancia en números',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        DateFilterBar(
          value: selected,
          today: today,
          onChanged: (value) => setState(() => filter = value),
        ),
        const SizedBox(height: 20),
        AsyncContent(
          value: ref.watch(dashboardProvider(selected)),
          onRetry: () => ref.invalidate(dashboardProvider(selected)),
          builder: (data) => DashboardCharts(data: data),
        ),
      ],
    );
  }
}

class DashboardCharts extends StatefulWidget {
  const DashboardCharts({super.key, required this.data});
  final DashboardData data;
  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts> {
  bool cumulative = false;
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final plannedMax = data.bars.fold<int>(
      0,
      (value, item) => math.max(value, item.planned),
    );
    final barStep = math.max(1, (plannedMax / 4).ceil()).toDouble();
    final colors = [
      Theme.of(context).colorScheme.primary,
      const Color(0xFFE5AA45),
      const Color(0xFFC46D5B),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _Indicator(
              value: '${data.completionPercentage.toStringAsFixed(1)}%',
              label: 'Cumplimiento del plan',
            ),
            _Indicator(
              value: '${data.goalsReached}',
              label: 'Metas alcanzadas',
            ),
            _Indicator(
              value: '${data.xpEarned}',
              label: 'XP ganado en el periodo',
            ),
            _Indicator(
              value: '${data.completionCount}',
              label: 'Sesiones completadas',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Evolución de experiencia',
          subtitle: cumulative
              ? 'XP acumulado, incluido el saldo anterior de ${data.openingXp} XP.'
              : 'XP ganado en cada intervalo según el día real de cumplimiento.',
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Ganado por intervalo'),
                      selected: !cumulative,
                      onSelected: (_) => setState(() => cumulative = false),
                    ),
                    ChoiceChip(
                      label: const Text('Acumulado'),
                      selected: cumulative,
                      onSelected: (_) => setState(() => cumulative = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: math.max(1, data.xpSeries.length - 1).toDouble(),
                    minY: 0,
                    maxY:
                        math
                            .max(
                              20,
                              data.xpSeries.fold<int>(
                                0,
                                (maximum, item) => math.max(
                                  maximum,
                                  cumulative
                                      ? item.cumulativeXp
                                      : item.earnedXp,
                                ),
                              ),
                            )
                            .toDouble() *
                        1.15,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: math
                              .max(1, (data.xpSeries.length / 4).ceil())
                              .toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            return index >= 0 && index < data.xpSeries.length
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      shortDate(data.xpSeries[index].startDate),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < data.xpSeries.length; i++)
                            FlSpot(
                              i.toDouble(),
                              (cumulative
                                      ? data.xpSeries[i].cumulativeXp
                                      : data.xpSeries[i].earnedXp)
                                  .toDouble(),
                            ),
                        ],
                        color: colors[0],
                        barWidth: 3,
                        isCurved: false,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors[0].withValues(alpha: .08),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots.map((spot) {
                          final index = spot.x.toInt();
                          final item = data.xpSeries[index];
                          return LineTooltipItem(
                            '${item.startDate} – ${item.endDate}\n${spot.y.toInt()} XP',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ExpansionTile(
                title: const Text('Ver valores del gráfico'),
                children: [
                  for (final item in data.xpSeries)
                    ListTile(
                      dense: true,
                      title: Text('${item.startDate} – ${item.endDate}'),
                      trailing: Text(
                        '${cumulative ? item.cumulativeXp : item.earnedXp} XP',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Planificación por categoría',
          subtitle:
              'Ocurrencias según su fecha programada. Una semana cuenta como un periodo.',
          child: Column(
            children: [
              const Wrap(
                spacing: 20,
                children: [Text('● Planificadas'), Text('● Completadas')],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: math.max(1, (plannedMax / barStep).ceil()) * barStep,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: barStep,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: barStep,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            return index < data.bars.length && index >= 0
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < data.bars.length; i++)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 5,
                          barRods: [
                            BarChartRodData(
                              toY: data.bars[i].planned.toDouble(),
                              color: colors[0].withValues(alpha: .25),
                              width: 16,
                            ),
                            BarChartRodData(
                              toY: data.bars[i].completed.toDouble(),
                              color: colors[0],
                              width: 16,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < data.bars.length; i++)
                ListTile(
                  dense: true,
                  title: Text('${i + 1}. ${data.bars[i].name}'),
                  trailing: Text(
                    '${data.bars[i].planned} / ${data.bars[i].completed}',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Estado de tus periodos',
          subtitle: 'Completados, pendientes y vencidos del rango programado.',
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: data.plannedOccurrences == 0
                    ? const Center(
                        child: Text('Sin periodos planificados en este rango'),
                      )
                    : PieChart(
                        PieChartData(
                          centerSpaceRadius: 52,
                          sectionsSpace: 4,
                          sections: [
                            for (var i = 0; i < data.slices.length; i++)
                              if (data.slices[i].count > 0)
                                PieChartSectionData(
                                  value: data.slices[i].count.toDouble(),
                                  color: colors[i],
                                  radius: 42,
                                  title:
                                      '${data.slices[i].percentage.toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          ],
                        ),
                      ),
              ),
              for (var i = 0; i < data.slices.length; i++)
                ListTile(
                  dense: true,
                  leading: Icon(Icons.circle, color: colors[i], size: 14),
                  title: Text(statusLabel(data.slices[i].status)),
                  trailing: Text(
                    '${data.slices[i].count} · ${data.slices[i].percentage.toStringAsFixed(1)}%',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Calendario de constancia',
          subtitle:
              'Sesiones completadas por día local registrado. Toca una casilla para ver el detalle.',
          child: HeatCalendar(days: data.heatmap),
        ),
        const SizedBox(height: 12),
        const Text(
          'El nivel y las rachas del resumen son globales. Los filtros solo afectan las estadísticas. Los días históricos conservan la zona horaria del momento del cumplimiento.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    ),
  );
}

class HeatCalendar extends StatelessWidget {
  const HeatCalendar({super.key, required this.days});
  final List<HeatDay> days;
  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const Text('Sin días en este rango.');
    final offset = DateTime.parse(days.first.date).weekday - 1;
    final weeks = ((days.length + offset) / 7).ceil();
    final maxCount = days.fold<int>(
      0,
      (value, day) => math.max(value, day.count),
    );
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 24),
                  for (final label in ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
                    SizedBox(
                      height: 25,
                      width: 24,
                      child: Center(
                        child: Text(label, style: TextStyle(fontSize: 11)),
                      ),
                    ),
                ],
              ),
              for (var week = 0; week < weeks; week++)
                Column(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 26,
                      child: week % 4 == 0
                          ? Text(
                              shortDate(
                                days[math.max(0, week * 7 - offset)].date,
                              ),
                              style: const TextStyle(fontSize: 9),
                            )
                          : null,
                    ),
                    for (var weekday = 0; weekday < 7; weekday++)
                      Builder(
                        builder: (context) {
                          final index = week * 7 + weekday - offset;
                          if (index < 0 || index >= days.length) {
                            return const SizedBox(width: 26, height: 25);
                          }
                          final day = days[index];
                          final label =
                              '${day.date}: ${day.count} cumplimientos';
                          return Tooltip(
                            message: label,
                            child: Semantics(
                              label: label,
                              button: true,
                              child: InkWell(
                                onTap: () => ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(label))),
                                child: Container(
                                  width: 21,
                                  height: 21,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: day.count == 0
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest
                                        : primary.withValues(
                                            alpha:
                                                .25 +
                                                .75 * day.count / maxCount,
                                          ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Menos  ░ ▒ ▓  Más · máximo $maxCount por día',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
