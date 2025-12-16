import 'package:flutter/material.dart';
import '../glass_effect.dart';

class TopicListLoadingWidget extends StatelessWidget {
  const TopicListLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(24.0),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载动态...'),
          ],
        ),
      ),
    );
  }
}