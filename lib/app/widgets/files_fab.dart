import 'package:flutter/material.dart';

class FilesFloatingActionButton extends StatefulWidget {
  final VoidCallback onUpload;
  final VoidCallback onCreateFolder;
  final VoidCallback? onTransfer;

  const FilesFloatingActionButton({
    super.key,
    required this.onUpload,
    required this.onCreateFolder,
    this.onTransfer,
  });

  @override
  State<FilesFloatingActionButton> createState() => _FilesFloatingActionButtonState();
}

class _FilesFloatingActionButtonState extends State<FilesFloatingActionButton>
    with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 添加动画状态监听器
    _animationController.addStatusListener((status) {
      print('[FAB] Animation status: $status');
    });
    
    _animationController.addListener(() {
      print('[FAB] Animation value: ${_animationController.value}, Scale: ${_scaleAnimation.value}');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    print('[FAB] _toggleFab called, current state: $_isFabExpanded');
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      print('[FAB] State changed to: $_isFabExpanded');
      if (_isFabExpanded) {
        _animationController.forward();
        print('[FAB] Animation forward started');
      } else {
        _animationController.reverse();
        print('[FAB] Animation reverse started');
      }
    });
  }

  // 执行操作后重置浮动按钮状态
  void _executeAction(VoidCallback action) {
    print('[FAB] _executeAction called');
    // 先收起浮动按钮
    if (_isFabExpanded) {
      print('[FAB] FAB is expanded, collapsing...');
      _toggleFab();
    }
    // 然后执行操作
    print('[FAB] Executing action...');
    action();
    print('[FAB] Action executed');
  }

  @override
  Widget build(BuildContext context) {
    // 使用更大的底部边距，确保浮动按钮完全显示在导航栏上方
    final bottomPadding = 100.0;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    print('[FAB] Building widget, expanded: $_isFabExpanded');

    if (_isFabExpanded) {
      print('[FAB] Building expanded FAB with scale: ${_scaleAnimation.value}');
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding), // 使用计算出的底部边距
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            // 上传文件按钮
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _scaleAnimation.value,
                child: FloatingActionButton.extended(
                  heroTag: "upload",
                  onPressed: () {
                    _executeAction(widget.onUpload);
                  },
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimaryColor,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('上传文件'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 创建文件夹按钮
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _scaleAnimation.value,
                child: FloatingActionButton.extended(
                  heroTag: "create_folder",
                  onPressed: () {
                    _executeAction(widget.onCreateFolder);
                  },
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimaryColor,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('新建文件夹'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 传输列表按钮
            if (widget.onTransfer != null)
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _scaleAnimation.value,
                  child: FloatingActionButton.extended(
                    heroTag: "transfer",
                    onPressed: () {
                      _executeAction(widget.onTransfer!);
                    },
                    backgroundColor: primaryColor,
                    foregroundColor: onPrimaryColor,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('传输列表'),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // 关闭按钮
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _scaleAnimation.value,
                child: FloatingActionButton.extended(
                  heroTag: "close",
                  onPressed: _toggleFab,
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  icon: const Icon(Icons.close),
                  label: const Text('关闭'),
                ),
              ),
            ),
              ],
            ),
          );
        },
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding), // 使用固定的底部边距
        child: FloatingActionButton(
          heroTag: "main_fab",
          onPressed: _toggleFab,
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 3.14159,
                child: child,
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      );
    }
  }
}
