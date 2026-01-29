import 'package:flutter/material.dart';
import 'conditional_glass_effect.dart';

// 定义浮动按钮的显示类型
enum FabDisplayType { modal, expandable }

class FilesFloatingActionButton extends StatefulWidget {
  final VoidCallback onUpload;
  final VoidCallback onCreateFolder;
  final VoidCallback? onTransfer;
  final FabDisplayType displayType;

  const FilesFloatingActionButton({
    super.key,
    required this.onUpload,
    required this.onCreateFolder,
    this.onTransfer,
    this.displayType = FabDisplayType.modal, // 默认使用模态方式
  });

  @override
  State<FilesFloatingActionButton> createState() => _FilesFloatingActionButtonState();
}

class _FilesFloatingActionButtonState extends State<FilesFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  // 底部弹窗内容
  void _showActionSheet(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ConditionalGlassEffect(  // 使用条件性玻璃效果，因为GlassBottomSheet有特定用途
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 拖拽手柄（可选，美观点）
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 标题
              Text(
                '添加新内容',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 选项按钮（大按钮，好点）
              _buildActionButton(
                context: context,
                icon: Icons.upload_file,
                label: '上传文件',
                color: primaryColor,
                textColor: theme.colorScheme.onSurface,
                onTap: () {
                  Navigator.pop(context); // 先关弹窗
                  widget.onUpload();
                },
              ),
              const SizedBox(height: 12),

              _buildActionButton(
                context: context,
                icon: Icons.create_new_folder,
                label: '新建文件夹',
                color: primaryColor,
                textColor: theme.colorScheme.onSurface,
                onTap: () {
                  Navigator.pop(context);
                  widget.onCreateFolder();
                },
              ),
              const SizedBox(height: 16),

              // 取消按钮（浅色）
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 统一的选项按钮样式
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 为按钮添加轻微的背景色，增强对比度
    // 使用主题色而不是纯白色，避免刺眼
    final buttonBgColor = isDark 
        ? theme.colorScheme.primary.withOpacity(0.15)
        : theme.colorScheme.primary.withOpacity(0.08);
    
    // 根据主题模式调整文字和图标颜色，确保在浅色模式下足够深
    final adjustedTextColor = isDark 
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withOpacity(0.9); // 浅色模式下加深文字颜色
    
    return ConditionalGlassEffect(
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      color: buttonBgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: adjustedTextColor, size: 28),
              const SizedBox(width: 20),
              Text(
                label,
                style: TextStyle(
                  color: adjustedTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建展开式子按钮
  Widget _buildSubButton(
    double offset,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Positioned(
      bottom: 56 + offset,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _expandAnimation.value,
            child: FloatingActionButton(
              heroTag: tooltip,
              mini: true,
              onPressed: onPressed,
              tooltip: tooltip,
              child: Icon(icon),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.displayType == FabDisplayType.expandable) {
      // 展开式浮动按钮
      return SizedBox(
        width: 56,
        height: 120,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 主按钮
            FloatingActionButton(
              heroTag: "main_fab",
              onPressed: _toggle,
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _expandAnimation,
              ),
            ),
            // 子按钮容器
            if (_isExpanded) ...[
              // 上传文件按钮
              _buildSubButton(
                0.0,
                Icons.upload_file,
                '上传',
                widget.onUpload,
              ),
              // 创建文件夹按钮
              _buildSubButton(
                -56.0,
                Icons.create_new_folder,
                '新建文件夹',
                widget.onCreateFolder,
              ),
            ],
          ],
        ),
      );
    } else {
      // 模态浮动按钮（原有功能）
      return Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 16), // 调整bottom值，使按钮往上移动
        child: FloatingActionButton(
          heroTag: "main_files_fab",
          onPressed: () => _showActionSheet(context),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 8,
          child: const Icon(Icons.add, size: 30),
        ),
      );
    }
  }
}