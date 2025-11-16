import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';
import '../services/local_file_service.dart';

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
  final Map<String, FileItemModel> _folderCache = {};

  // 简化实现，直接使用当前文件夹信息
  String _getCurrentFolderName() {
    final provider = context.read<FileProvider>();

    // 如果是根目录，返回"根目录"
    if (provider.currentFolderId == '-1') {
      return '根目录';
    }

    // 首先从缓存中查找
    if (_folderCache.containsKey(provider.currentFolderId)) {
      final cachedFolder = _folderCache[provider.currentFolderId];
      if (cachedFolder != null && cachedFolder.name.isNotEmpty) {
        return cachedFolder.name;
      }
    }

    // 尝试从当前文件列表中查找文件夹名称
    for (final file in provider.files) {
      if (file.id == provider.currentFolderId && file.isFolder) {
        final folderModel = FileItemModel(
          id: file.id,
          name: file.name,
          type: file.type,
          size: file.size,
          uploadTime: file.uploadTime,
          isFolder: file.isFolder,
          parentId: file.parentId,
        );
        _folderCache[provider.currentFolderId] = folderModel;
        return file.name.isNotEmpty ? file.name : '未命名文件夹';
      }
    }

    // 如果还是找不到，异步加载文件夹信息
    _getFolderInfo(provider.currentFolderId);

    return '加载中...';
  }

  List<String> _getPathSegments() {
    final provider = context.read<FileProvider>();
    final List<String> segments = ['根目录'];

    // 跳过根目录ID（-1）
    for (int i = 1; i < provider.pathHistory.length; i++) {
      final folderId = provider.pathHistory[i];
      String folderName = '加载中...';

      // 尝试从缓存中查找文件夹名称
      if (_folderCache.containsKey(folderId)) {
        folderName = _folderCache[folderId]!.name;
      } else {
        // 尝试从当前文件列表中查找文件夹名称
        for (final file in provider.files) {
          if (file.id == folderId && file.isFolder) {
            folderName = file.name;
            _folderCache[folderId] = FileItemModel(
              id: file.id,
              name: file.name,
              type: file.type,
              size: file.size,
              uploadTime: file.uploadTime,
              isFolder: file.isFolder,
              parentId: file.parentId,
            ); // 添加到缓存
            break;
          }
        }

        // 如果在当前列表中没找到，异步获取文件夹信息
        if (folderName == '加载中...' && !_folderCache.containsKey(folderId)) {
          _getFolderInfo(folderId);
        }
      }

      segments.add(folderName);
    }

    return segments;
  }

  Future<FileItemModel> _getFolderInfo(String folderId) async {
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
          _folderCache[folderId] = FileItemModel(
              id: file.id,
              name: file.name,
              type: file.type,
              size: file.size,
              uploadTime: file.uploadTime,
              isFolder: file.isFolder,
              parentId: file.parentId,
            );
          // 触发UI更新
          if (mounted) {
            setState(() {});
          }
          return _folderCache[folderId]!;
        }
      }

      // 在本地模式下，通过LocalFileService获取文件夹信息
      final loginMode = provider.userProvider?.loginMode ?? 'server';
      if (loginMode == 'local') {
        try {
          debugPrint('Fetching folder info via LocalFileService: $folderId');
          // 在本地模式下，遍历所有可能的父文件夹来查找目标文件夹
          await _searchFolderRecursively(folderId, provider);

          if (_folderCache.containsKey(folderId)) {
            debugPrint('Found folder via recursive search: ${_folderCache[folderId]!.name}');
            // 触发UI更新
            if (mounted) {
              setState(() {});
            }
            return _folderCache[folderId]!;
          }
        } catch (e) {
          debugPrint('Error loading folder info via LocalFileService: $e');
        }
      } else {
        // 服务器模式下，尝试通过API获取
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
                final file = FileItemModel.fromJson(fileData);
                debugPrint('Processing file: ${file.name}, ID: ${file.id}, isFolder: ${file.isFolder}');

                if (file.id == folderId && file.isFolder) {
                  debugPrint('Found matching folder: ${file.name}');
                  _folderCache[folderId] = file;

                  // 恢复当前状态
                  provider.setCurrentFolder(currentFolderId, currentPathHistory, notify: false);

                  // 触发UI更新
                  if (mounted) {
                    setState(() {});
                  }

                  return file;
                }
              }
            }
          }

          // 恢复当前状态
          provider.setCurrentFolder(currentFolderId, currentPathHistory, notify: false);
        } catch (e) {
          debugPrint('Error loading folder info via API: $e');
        }
      }
    } catch (e) {
      debugPrint('Error getting folder info: $e');
    }

    // 为本地模式提供更好的默认处理
    final provider = context.read<FileProvider>();
    final loginMode = provider.userProvider?.loginMode ?? 'server';
    String defaultName = loginMode == 'local' ? '本地文件夹' : '未知文件夹';

    debugPrint('Returning default folder for: $folderId');
    final defaultFolder = FileItemModel(
      id: folderId,
      name: defaultName,
      type: 'folder',
      size: 0,
      isFolder: true,
      uploadTime: DateTime.now(),
      parentId: '-1',
    );

    _folderCache[folderId] = defaultFolder;

    // 触发UI更新
    if (mounted) {
      setState(() {});
    }

    return defaultFolder;
  }

  // 递归搜索文件夹
  Future<void> _searchFolderRecursively(String targetFolderId, FileProvider provider) async {
    try {
      debugPrint('Recursively searching for folder: $targetFolderId');

      // 获取所有已知的文件夹ID（从路径历史中）
      final Set<String> folderIdsToSearch = Set<String>.from(provider.pathHistory);

      for (final folderId in folderIdsToSearch) {
        if (folderId == '-1') continue; // 跳过根目录

        try {
          final localFiles = await LocalFileService().getFiles(folderId: folderId);
          debugPrint('Found ${localFiles.length} files in folder $folderId');

          for (final file in localFiles) {
            if (file.id == targetFolderId && file.isFolder) {
              debugPrint('Found target folder $targetFolderId in parent $folderId: ${file.name}');
              // 将FileItem转换为FileItemModel，确保类型正确
              final folderName = file.name.isNotEmpty ? file.name : '未命名文件夹';
              _folderCache[targetFolderId] = FileItemModel(
                id: file.id,
                name: folderName,
                type: file.type.isNotEmpty ? file.type : 'folder',
                size: file.size,
                uploadTime: file.uploadTime,
                isFolder: file.isFolder,
                parentId: file.parentId.isNotEmpty ? file.parentId : '-1',
              );
              return;
            }
          }
        } catch (e) {
          debugPrint('Error searching folder $folderId: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in recursive search: $e');
    }
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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