
import 'package:flutter/material.dart';

class TransferTab extends StatefulWidget {
  const TransferTab({super.key});

  @override
  State<TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<TransferTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            '传输列表',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 选项卡
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '上传'),
            Tab(text: '下载'),
          ],
        ),

        // 选项卡内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _UploadTab(),
              _DownloadTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadTab extends StatelessWidget {
  const _UploadTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('暂无上传任务'),
    );
  }
}

class _DownloadTab extends StatelessWidget {
  const _DownloadTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('暂无下载任务'),
    );
  }
}
