import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: light ? AppTheme.mint : AppTheme.green,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: light ? AppTheme.ink : Colors.white,
          size: 23,
        ),
      ),
      const SizedBox(width: 11),
      Text(
        'ritmo',
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: light ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );
}
