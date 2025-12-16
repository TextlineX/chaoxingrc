// 传输页面 - 显示所有传输任务
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transfer_provider.dart';
import '../../models/transfer_task.dart';
import '../../widgets/transfer_task_item.dart';
import '../../widgets/glass_effect.dart';

class TransferTab extends StatefulWidget {
  const TransferTab({super.key, this.showTitle = false});

  final bool showTitle;

  @override
  State<TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<TransferTab>
    with SingleTickerProviderStateMixin {
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
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // 设置背景为透明
      primary: false, // 嵌套在 HomeScreen 中，不需要处理顶部状态栏区域
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
                primaryColor.withValues(alpha: 0.1),
                primaryColor.withValues(alpha: 0.05),
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
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: primaryColor,
          tabs: const [
            Tab(text: '下载任务'),
            Tab(text: '上传任务'),
          ],
        ),
        actions: [
          Consumer<TransferProvider>(
            builder: (context, provider, child) => PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: primaryColor),
              color: colorScheme.surface,
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
      body: GlassEffect(
        blur: 15,
        opacity: isDark ? 0.05 : 0.1,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTransferList(TransferType.download),
            _buildTransferList(TransferType.upload),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(TransferTask task) {
    String statusText = '';
    Color statusColor = Colors.grey;

    switch (task.status) {
      case TransferStatus.pending:
        statusText = '等待中';
        break;
      case TransferStatus.paused:
        statusText = '已暂停';
        statusColor = Colors.orange;
        break;
      case TransferStatus.uploading:
        statusText = '上传中';
        statusColor = Colors.blue;
        break;
      case TransferStatus.downloading:
        statusText = '下载中';
        statusColor = Colors.blue;
        break;
      case TransferStatus.completed:
        statusText = '已完成';
        statusColor = Colors.green;
        break;
      case TransferStatus.failed:
        statusText = '失败';
        statusColor = Colors.red;
        break;
      case TransferStatus.cancelled:
        statusText = '已取消';
        break;
    }

    return Text(
      statusText,
      style: TextStyle(
        fontSize: 12,
        color: statusColor,
      ),
    );
  }

  Widget _buildTrailingIcons(BuildContext context, TransferTask task, TransferProvider provider) {
    switch (task.status) {
      case TransferStatus.pending:
      case TransferStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => provider.resumeTask(task.id),
              tooltip: '继续',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => GlassDialog(
                    title: const Text('确认删除'),
                    content: const Text('确定要删除此任务吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          provider.deleteTask(task.id);
                        },
                        child: const Text('删除',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: '删除',
            ),
          ],
        );
      case TransferStatus.uploading:
      case TransferStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => provider.pauseTask(task.id),
              tooltip: '暂停',
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => provider.cancelTask(task.id),
              tooltip: '取消',
            ),
          ],
        );
      case TransferStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => provider.openFile(task.id),
              tooltip: '打开文件',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => GlassDialog(
                    title: const Text('确认删除'),
                    content: const Text('确定要删除此任务吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          provider.deleteTask(task.id);
                        },
                        child: const Text('删除',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: '删除记录',
            ),
          ],
        );
      case TransferStatus.failed:
      case TransferStatus.cancelled:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red),
              onPressed: () => provider.retryTask(task.id),
              tooltip: '重试',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => GlassDialog(
                    title: const Text('确认删除'),
                    content: const Text('确定要删除此任务吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          provider.deleteTask(task.id);
                        },
                        child: const Text('删除',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: '删除记录',
            ),
          ],
        );
    }
  }

  Widget _buildTransferList(TransferType type) {
    // 获取主题颜色
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<TransferProvider>(
      builder: (context, provider, child) {
        final tasks = type == TransferType.upload
            ? provider.uploadTasks
            : provider.downloadTasks;

        if (tasks.isEmpty) {
          return Center(
            child: GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: type == TransferType.upload
                        ? Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: primaryColor,
                          )
                        : Icon(
                            Icons.cloud_download,
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
                      color: colorScheme.onSurfaceVariant,
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
            provider.refresh();
          },
          child: GlassEffectWithScrollConfiguration(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // 为底部导航栏留出空间
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return GlassListTile(
                  title: Text(task.fileName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: task.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          task.status == TransferStatus.paused
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildStatusText(task),
                              const SizedBox(width: 8),
                              Text(task.formattedSize),
                            ],
                          ),
                          Text(task.progressPercentage),
                        ],
                      ),
                      if (task.errorMessage != null)
                        Text(task.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  trailing: _buildTrailingIcons(context, task, provider),
                );
              },
            ),
          ),
        );
      },
    );
  }
}