import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';
import 'package:flutter/foundation.dart';

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
  final Map<String, FileItem> _folderCache = {};

  // 简化实现，直接使用当前文件夹信息
  String _getCurrentFolderName() {
    final provider = context.read<FileProvider>();

    // 如果是根目录，返回"根目录"
    if (provider.currentFolderId == '-1') {
      return '根目录';
    }

    // 尝试从当前文件列表中查找文件夹名称
    for (final file in provider.files) {
      if (file.id == provider.currentFolderId && file.isFolder) {
        return file.name;
      }
    }

    // 如果找不到，返回"未知文件夹"
    return '未知文件夹';
  }

  List<String> _getPathSegments() {
    final provider = context.read<FileProvider>();
    final List<String> segments = ['根目录'];

    // 跳过根目录ID（-1）
    for (int i = 1; i < provider.pathHistory.length; i++) {
      final folderId = provider.pathHistory[i];
      String folderName = '未知文件夹';

      // 尝试从缓存中查找文件夹名称
      if (_folderCache.containsKey(folderId)) {
        folderName = _folderCache[folderId]!.name;
      } else {
        // 尝试从当前文件列表中查找文件夹名称
        for (final file in provider.files) {
          if (file.id == folderId && file.isFolder) {
            folderName = file.name;
            _folderCache[folderId] = file; // 添加到缓存
            break;
          }
        }
      }

      segments.add(folderName);
    }

    return segments;
  }

  Future<FileItem> _getFolderInfo(String folderId) async {
    debugPrint('Getting folder info for: $folderId');

    if (_folderCache.containsKey(folderId)) {
      debugPrint('Found folder in cache: ${_folderCache[folderId]!.name}');
      return _folderCache[folderId]!;
    }

    try {
      // 首先尝试从当前加载的文件列表中查找
      final provider = context.read<FileProvider>();
      debugPrint('Current files count: ${provider.files.length}');
      for (final file in provider.files) {
        debugPrint('Checking file: ${file.name}, ID: ${file.id}, isFolder: ${file.isFolder}');
        if (file.id == folderId && file.isFolder) {
          debugPrint('Found folder in current files: ${file.name}');
          _folderCache[folderId] = file;
          return file;
        }
      }

      // 如果当前列表中没有，则通过API获取文件夹信息
      try {
        // 保存当前状态
        final currentFolderId = provider.currentFolderId;
        final currentPathHistory = List<String>.from(provider.pathHistory);

        // 获取文件夹信息
        debugPrint('Fetching folder from API: $folderId');
        final response = await provider.apiService.getFileIndex();
        debugPrint('API response: $response');

        if (response['success'] == true && response['data'] is List) {
          final filesList = response['data'] as List;
          debugPrint('Files list count: ${filesList.length}');

          for (final fileData in filesList) {
            if (fileData is Map<String, dynamic>) {
              final file = FileItem.fromJson(fileData);
              debugPrint('Processing file: ${file.name}, ID: ${file.id}, isFolder: ${file.isFolder}');

              if (file.id == folderId && file.isFolder) {
                debugPrint('Found matching folder: ${file.name}');
                _folderCache[folderId] = file;

                // 恢复当前状态
                provider.setCurrentFolder(currentFolderId, currentPathHistory, notify: false);

                return file;
              }
            }
          }
        }

        // 恢复当前状态
        provider.setCurrentFolder(currentFolderId, currentPathHistory, notify: false);
      } catch (e) {
        debugPrint('Error loading folder info: $e');
      }
    } catch (e) {
      debugPrint('Error getting folder info: $e');
    }

    debugPrint('Returning unknown folder for: $folderId');
    return FileItem(
      id: folderId,
      name: '未知文件夹',
      type: '',
      size: 0,
      isFolder: true,
      uploadTime: DateTime.now(),
    );
  }

  // 预加载路径信息
  Future<void> _preloadPathInfo(FileProvider provider) async {
    for (int i = 1; i < provider.pathHistory.length; i++) {
      final folderId = provider.pathHistory[i];
      if (!_folderCache.containsKey(folderId)) {
        await _getFolderInfo(folderId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        // 预加载路径信息
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _preloadPathInfo(provider);
        });

        final pathSegments = _getPathSegments();
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildPathButtons(provider, pathSegments),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPathButtons(FileProvider provider, List<String> pathSegments) {
    final List<Widget> buttons = [];

    // 添加根目录按钮
    buttons.add(TextButton(
      onPressed: () => provider.goToRoot(),
      child: Text(pathSegments.isNotEmpty ? pathSegments[0] : '根目录'),
    ));

    // 添加路径中的其他文件夹按钮
    for (int i = 1; i < pathSegments.length; i++) {
      buttons.add(const Icon(Icons.chevron_right));

      final folderId = i < provider.pathHistory.length ? provider.pathHistory[i] : '-1';
      buttons.add(TextButton(
        onPressed: () {
          if (folderId != '-1') {
            final newPathHistory = provider.pathHistory.sublist(0, i + 1);
            provider.navigateToFolder(folderId, newPathHistory);
          }
        },
        child: Text(pathSegments[i]),
      ));
    }

    return buttons;
  }
}