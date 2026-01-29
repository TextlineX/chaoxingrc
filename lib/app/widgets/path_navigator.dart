import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import 'conditional_glass_effect.dart';

class PathNavigator extends StatefulWidget {
  final FileProvider provider;
  final bool embedded;

  const PathNavigator({
    super.key,
    required this.provider,
    this.embedded = false,
  });

  @override
  State<PathNavigator> createState() => _PathNavigatorState();
}

class _PathNavigatorState extends State<PathNavigator> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileProvider>();
    final history = provider.pathHistory;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: history.length,
        separatorBuilder: (context, index) => Icon(
          Icons.chevron_right,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        itemBuilder: (context, index) {
          final segment = history[index];
          final isLast = index == history.length - 1;

          return InkWell(
            onTap: isLast
                ? null
                : () async {
                    final steps = history.length - 1 - index;
                    for (int i = 0; i < steps; i++) {
                      await provider.navigateBack();
                    }
                  },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                segment['name'] ?? '未知',
                style: TextStyle(
                  color: isLast
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return ConditionalGlassEffect(
      blur: 10,
      opacity: isDark ? 0.05 : 0.1,
      padding: EdgeInsets.zero,
      child: content,
    );
  }
}