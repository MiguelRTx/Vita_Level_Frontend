import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/application/dashboard_providers.dart';
import '../../features/dashboard/data/dashboard.dart';
import '../dates.dart';

class DateFilterBar extends ConsumerWidget {
  const DateFilterBar({
    super.key,
    required this.value,
    required this.today,
    required this.onChanged,
    this.showCategory = true,
    this.showInterval = true,
  });
  final StatisticsFilter value;
  final DateTime today;
  final ValueChanged<StatisticsFilter> onChanged;
  final bool showCategory, showInterval;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 12,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.date_range),
        label: Text('${value.from}  →  ${value.to}'),
        onPressed: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: today,
            initialDateRange: DateTimeRange(
              start: DateTime.parse(value.from),
              end: DateTime.parse(value.to),
            ),
            helpText: 'Selecciona hasta 366 días',
            saveText: 'Aplicar',
          );
          if (range == null || !context.mounted) return;
          if (range.duration.inDays > 365) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El rango máximo es de 366 días.')),
            );
            return;
          }
          onChanged((
            from: civilDate(range.start),
            to: civilDate(range.end),
            categoryId: value.categoryId,
            interval: value.interval,
          ));
        },
      ),
      if (showCategory)
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            key: ValueKey(value.categoryId),
            initialValue: value.categoryId ?? '',
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Todas las categorías'),
              ),
              for (final category
                  in ref.watch(categoriesProvider).valueOrNull ?? [])
                DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: (category) => onChanged((
              from: value.from,
              to: value.to,
              categoryId: category == '' ? null : category,
              interval: value.interval,
            )),
          ),
        ),
      if (showInterval)
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'WEEK', label: Text('Semana')),
            ButtonSegment(value: 'MONTH', label: Text('Mes')),
          ],
          selected: {value.interval},
          onSelectionChanged: (selection) => onChanged((
            from: value.from,
            to: value.to,
            categoryId: value.categoryId,
            interval: selection.first,
          )),
        ),
    ],
  );
}
