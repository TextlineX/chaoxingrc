import 'package:flutter/material.dart';

class FabMenu extends StatelessWidget {
  final VoidCallback onUpload;
  final VoidCallback onCreateFolder;

  const FabMenu({
    Key? key,
    required this.onUpload,
    required this.onCreateFolder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showMenu(context),
      child: const Icon(Icons.add),
    );
  }

  void _showMenu(BuildContext context) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox fab = context.findRenderObject() as RenderBox;
    final Offset offset = Offset(0, fab.size.height);
    final RelativeRect position = RelativeRect.fromRect(
      fab.localToGlobal(offset, ancestor: overlay) & fab.size,
      Offset.zero & overlay.size,
    );
    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'upload',
          child: Row(
            children: const [
              Icon(Icons.upload_file),
              SizedBox(width: 8),
              Text('上传文件'),
            ],
          ),
          onTap: () {
            Navigator.pop(context);
            onUpload();
          },
        ),
        PopupMenuItem(
          value: 'create_folder',
          child: Row(
            children: const [
              Icon(Icons.create_new_folder),
              SizedBox(width: 8),
              Text('新建文件夹'),
            ],
          ),
          onTap: () {
            Navigator.pop(context);
            onCreateFolder();
          },
        ),
      ],
    );
  }
}
