import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../providers/file_provider.dart';

class DirectoryTreeView extends StatefulWidget {
  final List<FileItem> initialFolders;
  final List<Map<String, String>> currentPath;
  final List<FileItem> selectedItems;
  final Function(String, String) onSelect;

  const DirectoryTreeView({
    Key? key,
    required this.initialFolders,
    required this.currentPath,
    required this.selectedItems,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<DirectoryTreeView> createState() => _DirectoryTreeViewState();
}

class _DirectoryTreeViewState extends State<DirectoryTreeView> {
  late List<_TreeNode> _treeNodes;
  late Map<String, List<FileItem>> _loadedSubfolders;
  Set<String> _expandedNodes = {};
  String? _currentLoadingNodeId;

  @override
  void initState() {
    super.initState();
    _treeNodes = _buildInitialTree();
    _loadedSubfolders = {};
    // 默认展开根节点
    if (_treeNodes.isNotEmpty) {
      _expandedNodes.add(_treeNodes.first.id);
    }
  }

  List<_TreeNode> _buildInitialTree() {
    List<_TreeNode> nodes = [];

    // 添加根目录节点
    nodes.add(_TreeNode(
      id: '-1',
      name: '📁 根目录',
      level: 0,
      hasChildren: true,
      parentId: null,
    ));

    // 添加根目录下的文件夹
    for (var folder in widget.initialFolders) {
      nodes.add(_TreeNode(
        id: folder.id,
        name: '📁 ${folder.name}',
        level: 1,
        hasChildren: true,  // 假设所有文件夹都可能有子文件夹
        parentId: '-1',
      ));
    }

    return nodes;
  }

  Future<List<FileItem>> _loadSubfolders(FileProvider fileProvider, String folderId) async {
    if (_loadedSubfolders.containsKey(folderId)) {
      return _loadedSubfolders[folderId]!;
    }

    try {
      final subfolders = await fileProvider.getSubfolders(folderId);
      _loadedSubfolders[folderId] = subfolders;
      return subfolders;
    } catch (e) {
      debugPrint('加载子文件夹失败: $e');
      return [];
    }
  }

  void _toggleNodeExpansion(FileProvider fileProvider, _TreeNode node) async {
    if (node.id == _currentLoadingNodeId) return; // 防止重复加载

    if (_expandedNodes.contains(node.id)) {
      // 收起节点
      _expandedNodes.remove(node.id);
      // 同时移除所有子节点
      _expandedNodes.removeWhere((id) => 
          _treeNodes.any((n) => n.id == id && _isDescendantOf(n, node)));
    } else {
      // 展开节点
      _currentLoadingNodeId = node.id;
      setState(() {});
      
      final subfolders = await _loadSubfolders(fileProvider, node.id);
      
      // 添加子节点
      for (var folder in subfolders) {
        // 检查是否已经存在该节点
        bool exists = _treeNodes.any((n) => n.id == folder.id);
        if (!exists) {
          _treeNodes.add(_TreeNode(
            id: folder.id,
            name: '📁 ${folder.name}',
            level: node.level + 1,
            hasChildren: true,  // 假设所有文件夹都可能有子文件夹
            parentId: node.id,
          ));
        }
      }
      
      _expandedNodes.add(node.id);
      _currentLoadingNodeId = null;
    }
    
    setState(() {});
  }

  bool _isDescendantOf(_TreeNode child, _TreeNode parent) {
    var current = child.parentId;
    while (current != null) {
      if (current == parent.id) return true;
      // 查找父节点
      final parentNode = _treeNodes.firstWhere((n) => n.id == current, orElse: () => parent);
      current = parentNode.parentId;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        return Column(
          children: [
            // 显示当前位置
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: Text(
                '当前位置: ${_getCurrentPathDisplay()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: _treeNodes.length,
                  itemBuilder: (context, index) {
                    final node = _treeNodes[index];
                    
                    // 检查该节点是否应该显示（在其父节点展开的情况下）
                    bool shouldShow = _shouldShowNode(node);
                    
                    if (!shouldShow) {
                      return const SizedBox.shrink();
                    }

                    final isSelected = widget.currentPath.any((path) => path['id'] == node.id);
                    final isCurrentFolder = widget.currentPath.last['id'] == node.id;
                    
                    return _buildTreeNode(fileProvider, node, isSelected, isCurrentFolder);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowNode(_TreeNode node) {
    if (node.level == 0) return true; // 根节点始终显示
    
    var currentParentId = node.parentId;
    while (currentParentId != null) {
      if (!_expandedNodes.contains(currentParentId)) {
        return false; // 如果任一父节点未展开，则不显示
      }
      // 查找父节点的父节点
      final parentNode = _treeNodes.firstWhere((n) => n.id == currentParentId, orElse: () => _TreeNode(id: '', name: '', level: 0, hasChildren: false, parentId: null));
      currentParentId = parentNode.parentId;
    }
    
    return true;
  }

  Widget _buildTreeNode(FileProvider fileProvider, _TreeNode node, bool isSelected, bool isCurrentFolder) {
    final hasChildren = node.hasChildren;
    final isExpanded = _expandedNodes.contains(node.id);
    
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(
            left: 16.0 + (node.level * 24.0),
            right: 16.0,
          ),
          leading: hasChildren
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isExpanded 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Colors.orange,
                  ),
                ),
          title: Text(
            node.name.split(' ').length > 1 ? node.name.substring(3) : node.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isCurrentFolder 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).textTheme.titleMedium?.color,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: isCurrentFolder ? const Text(
            '当前目录',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ) : null,
          trailing: (node.id == _currentLoadingNodeId)
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : null,
          selected: isSelected,
          selectedColor: Theme.of(context).colorScheme.primary,
          onTap: () {
            if (node.id != '-1' || 
                !widget.selectedItems.any((item) => item.id == widget.currentPath.last['id'])) {
              // 不允许移动到自身所在的文件夹
              widget.onSelect(node.id, node.name.startsWith('📁 ') ? node.name.substring(3) : node.name);
            }
          },
          minVerticalPadding: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // 为展开的节点添加轻微的背景区分
        if (isExpanded && node.level < 5) // 限制层级以避免过度嵌套视觉效果
          Container(
            margin: EdgeInsets.only(left: 16.0 + (node.level * 24.0), right: 16, top: 2, bottom: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            height: 1,
          ),
      ],
    );
  }

  String _getCurrentPathDisplay() {
    if (widget.currentPath.isEmpty) return '📁 根目录';
    
    String pathStr = widget.currentPath.map((path) => path['name']).join(' / ');
    // 如果路径太长，截断并添加省略号
    if (pathStr.length > 40) {
      pathStr = '...${pathStr.substring(pathStr.length - 40)}';
    }
    return pathStr;
  }
}

class _TreeNode {
  final String id;
  final String name;
  final int level;
  final bool hasChildren;
  final String? parentId;

  _TreeNode({
    required this.id,
    required this.name,
    required this.level,
    required this.hasChildren,
    this.parentId,
  });
}