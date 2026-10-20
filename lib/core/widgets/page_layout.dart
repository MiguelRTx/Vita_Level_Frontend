import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.children,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions, children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 36),
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 14,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ...actions,
        ],
      ),
      if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!)],
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onChanged,
  });
  final int page, totalPages;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        tooltip: 'Página anterior',
        onPressed: page > 1 ? () => onChanged(page - 1) : null,
        icon: const Icon(Icons.chevron_left),
      ),
      Text(totalPages == 0 ? 'Sin resultados' : '$page de $totalPages'),
      IconButton(
        tooltip: 'Página siguiente',
        onPressed: page < totalPages ? () => onChanged(page + 1) : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

String frequencyLabel(String frequency) => switch (frequency) {
  'DAILY' => 'Diaria',
  'WEEKLY' => 'Semanal',
  _ => 'Única',
};
String statusLabel(String status) => switch (status) {
  'COMPLETED' => 'Completada',
  'OVERDUE' => 'Vencida',
  _ => 'Pendiente',
};
