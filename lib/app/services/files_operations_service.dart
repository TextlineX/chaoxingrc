import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/file_provider.dart';
import '../providers/transfer_provider.dart';
import '../models/file_item.dart';
import '../utils/file_operations.dart';
import 'dart:io';

class FilesOperationsService {
  static Future<void> showCreateFolderDialog(
    BuildContext context,
    FileProvider provider, {
    TextEditingController? controller,
  }) async {
    final textController = controller ?? TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                await provider.createFolder(
                  name,
                  parentId: provider.currentFolderId,
                );
                textController.clear();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  static Future<void> showUploadDialog(
    BuildContext context,
    FileProvider fileProvider,
    {TransferProvider? transferProvider}
  ) async {
    try {
      // 使用file_selector选择文件，添加文件大小限制
      const maxFileSize = 100 * 1024 * 1024; // 100MB
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: '所有文件',
            extensions: <String>['*'],
          ),
        ],
        initialDirectory: '/storage/emulated/0',
      );
      
      // 检查文件大小
      if (file != null) {
        final fileSize = await file.length();
        if (fileSize > maxFileSize) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('文件大小超过100MB限制，请选择较小的文件'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        final filePath = file.path;
        final fileName = file.name;
        
        // 文件大小已在上面获取，不需要重复获取
        final fileObj = File(filePath);
        

        
        // 获取传输提供者
        transferProvider ??= Provider.of<TransferProvider>(context, listen: false);
        
        // 设置文件提供者
        transferProvider?.setFileProvider(fileProvider);
        
        // 添加上传任务
        transferProvider?.addUploadTask(
          filePath: filePath,
          fileName: fileName,
          fileSize: fileSize,
          dirId: fileProvider.currentFolderId,
        );
        
        // 判断是否为大文件（大于20MB）
        final isLargeFile = fileSize > 20 * 1024 * 1024;
        
        // 显示任务已添加提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLargeFile ? '大文件已添加到分块上传队列' : '文件已添加到上传队列'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加上传任务失败: $e')),
        );
      }
    }
  }

  // 显示删除确认对话框
  static Future<void> showDeleteConfirmation(
    BuildContext context,
    FileProvider provider,
    FileItem file,
  ) async {
    FileOperations.showDeleteConfirmation(
      context,
      file,
      () async {
        try {
          await provider.deleteResource(file.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除成功: ${file.name}')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败: $e')),
            );
          }
        }
      },
    );
  }
}
