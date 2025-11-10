// 简单浮动按钮 - 点击展开子菜单
import 'package:flutter/material.dart';

class SimpleFloatingActionButton extends StatefulWidget {
  final VoidCallback onUploadPressed;
  final VoidCallback onCreateFolderPressed;

  const SimpleFloatingActionButton({
    super.key,
    required this.onUploadPressed,
    required this.onCreateFolderPressed,
  });

  @override
  State<SimpleFloatingActionButton> createState() => _SimpleFloatingActionButtonState();
}

class _SimpleFloatingActionButtonState extends State<SimpleFloatingActionButton>
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

  @override
  Widget build(BuildContext context) {
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
              widget.onUploadPressed,
            ),
            // 创建文件夹按钮
            _buildSubButton(
              -56.0,
              Icons.create_new_folder,
              '新建文件夹',
              widget.onCreateFolderPressed,
            ),
          ],
        ],
      ),
    );
  }

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
              child: Icon(icon),
              tooltip: tooltip,
            ),
          );
        },
      ),
    );
  }
}
