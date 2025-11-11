// 传输页面 - 显示所有传输任务
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transfer_provider.dart';
import '../../models/transfer_task.dart';
import '../../widgets/transfer_task_item.dart';
import '../../widgets/custom_cloud_icons.dart';

class TransferTab extends StatefulWidget {
  const TransferTab({super.key, this.showTitle = false});
  
  final bool showTitle;

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
    // 获取主题颜色
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: widget.showTitle ? const Text('传输列表') : null,
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.1),
                primaryColor.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: primaryColor,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: primaryColor,
          tabs: const [
            Tab(text: '上传任务'),
            Tab(text: '下载任务'),
          ],
        ),
        actions: [
          Consumer<TransferProvider>(
            builder: (context, provider, child) => PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: primaryColor),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              onSelected: (value) {
                if (value == 'clear_completed') {
                  provider.clearCompletedTasks();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services),
                      SizedBox(width: 8),
                      Text('清除已完成'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransferList(TransferType.upload),
          _buildTransferList(TransferType.download),
        ],
      ),
    );
  }

  Widget _buildTransferList(TransferType type) {
    // 获取主题颜色
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Consumer<TransferProvider>(
      builder: (context, provider, child) {
        final tasks = type == TransferType.upload
            ? provider.uploadTasks
            : provider.downloadTasks;

        if (tasks.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: type == TransferType.upload
                      ? CustomCloudUploadIcon(
                          size: 48,
                          color: primaryColor,
                        )
                      : CustomCloudDownloadIcon(
                          size: 48,
                          color: primaryColor,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无${type == TransferType.upload ? '上传' : '下载'}任务',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type == TransferType.upload
                        ? '点击上传按钮开始上传文件'
                        : '点击下载按钮开始下载文件',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // 刷新传输列表
            provider.notifyListeners();
          },
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TransferTaskItem(
                task: task,
                onCancel: () => provider.cancelTask(task.id),
                onRetry: () => provider.retryTask(task.id),
              );
            },
          ),
        );
      },
    );
  }
}
