import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.task_alt_outlined,
              size: 52,
              color: (() {
                final c = Theme.of(context).textTheme.bodyMedium?.color;
                if (c == null) return null;
                return c.withAlpha((255 * 0.55).round());
              })(),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: (() {
                        final c = Theme.of(context).textTheme.bodyMedium?.color;
                        if (c == null) return null;
                        return c.withAlpha((255 * 0.75).round());
                      })(),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

