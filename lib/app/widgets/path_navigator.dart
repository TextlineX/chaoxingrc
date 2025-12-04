import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';

class PathNavigator extends StatefulWidget {
  final FileProvider provider;

  const PathNavigator({
    super.key,
    required this.provider,
  });

  @override
  State<PathNavigator> createState() => _PathNavigatorState();
}

class _PathNavigatorState extends State<PathNavigator> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileProvider>();
    final history = provider.pathHistory;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: history.length,
        separatorBuilder: (context, index) => const Icon(
          Icons.chevron_right,
          size: 20,
          color: Colors.grey,
        ),
        itemBuilder: (context, index) {
          final segment = history[index];
          final isLast = index == history.length - 1;

          return InkWell(
            onTap: isLast
                ? null
                : () async {
                    int steps = history.length - 1 - index;
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
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
