
import 'package:flutter/foundation.dart';

/// 权限模型类，用于管理用户对文件和文件夹的操作权限
class PermissionModel {
  // 小组权限
  final bool canAddData; // 添加数据
  final bool canAddDataFolder; // 添加数据文件夹
  final bool canDelData; // 删除数据
  final bool canDelDataFolder; // 删除数据文件夹
  final bool canModifyDataFolder; // 修改数据文件夹
  final bool canShowDataFolder; // 显示数据文件夹
  final bool canBatchOperation; // 批量操作

  // 操作权限
  final bool canAdd; // 添加文件
  final bool canDelete; // 删除文件
  final bool canUpdate; // 更新文件
  final bool canShare; // 分享文件
  final bool canReply; // 回复/评论

  PermissionModel({
    this.canAddData = false,
    this.canAddDataFolder = false,
    this.canDelData = false,
    this.canDelDataFolder = false,
    this.canModifyDataFolder = false,
    this.canShowDataFolder = false,
    this.canBatchOperation = false,
    this.canAdd = false,
    this.canDelete = false,
    this.canUpdate = false,
    this.canShare = false,
    this.canReply = false,
  });

  /// 从API响应创建权限模型
  factory PermissionModel.fromApiResponse(Map<String, dynamic> data) {
    final groupAuth = data['groupAuth'] as Map<String, dynamic>? ?? {};
    final operationAuth = data['operationAuth'] as Map<String, dynamic>? ?? {};

    return PermissionModel(
      canAddData: groupAuth['addData'] == 1,
      canAddDataFolder: groupAuth['addDataFolder'] == 1,
      canDelData: groupAuth['delData'] == 1,
      canDelDataFolder: groupAuth['delDataFolder'] == 1,
      canModifyDataFolder: groupAuth['modifyDataFolder'] == 1,
      canShowDataFolder: groupAuth['showDataFolder'] == 1,
      canBatchOperation: groupAuth['batchOperation'] == 1,
      canAdd: operationAuth['add'] == 1,
      canDelete: operationAuth['delete'] == 1,
      canUpdate: operationAuth['update'] == 1,
      canShare: operationAuth['share'] == 1,
      canReply: operationAuth['reply'] == 1,
    );
  }

  /// 创建一个具有所有权限的模型（用于管理员）
  factory PermissionModel.admin() {
    return PermissionModel(
      canAddData: true,
      canAddDataFolder: true,
      canDelData: true,
      canDelDataFolder: true,
      canModifyDataFolder: true,
      canShowDataFolder: true,
      canBatchOperation: true,
      canAdd: true,
      canDelete: true,
      canUpdate: true,
      canShare: true,
      canReply: true,
    );
  }

  /// 创建一个没有任何权限的模型（用于未登录或无权限用户）
  factory PermissionModel.none() {
    return PermissionModel();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'canAddData': canAddData,
      'canAddDataFolder': canAddDataFolder,
      'canDelData': canDelData,
      'canDelDataFolder': canDelDataFolder,
      'canModifyDataFolder': canModifyDataFolder,
      'canShowDataFolder': canShowDataFolder,
      'canBatchOperation': canBatchOperation,
      'canAdd': canAdd,
      'canDelete': canDelete,
      'canUpdate': canUpdate,
      'canShare': canShare,
      'canReply': canReply,
    };
  }

  /// 从JSON创建
  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      canAddData: json['canAddData'] ?? false,
      canAddDataFolder: json['canAddDataFolder'] ?? false,
      canDelData: json['canDelData'] ?? false,
      canDelDataFolder: json['canDelDataFolder'] ?? false,
      canModifyDataFolder: json['canModifyDataFolder'] ?? false,
      canShowDataFolder: json['canShowDataFolder'] ?? false,
      canBatchOperation: json['canBatchOperation'] ?? false,
      canAdd: json['canAdd'] ?? false,
      canDelete: json['canDelete'] ?? false,
      canUpdate: json['canUpdate'] ?? false,
      canShare: json['canShare'] ?? false,
      canReply: json['canReply'] ?? false,
    );
  }

  @override
  String toString() {
    return 'PermissionModel(canAddData: $canAddData, canAddDataFolder: $canAddDataFolder, '
        'canDelData: $canDelData, canDelDataFolder: $canDelDataFolder, '
        'canModifyDataFolder: $canModifyDataFolder, canShowDataFolder: $canShowDataFolder, '
        'canBatchOperation: $canBatchOperation, canAdd: $canAdd, canDelete: $canDelete, '
        'canUpdate: $canUpdate, canShare: $canShare, canReply: $canReply)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionModel &&
        other.canAddData == canAddData &&
        other.canAddDataFolder == canAddDataFolder &&
        other.canDelData == canDelData &&
        other.canDelDataFolder == canDelDataFolder &&
        other.canModifyDataFolder == canModifyDataFolder &&
        other.canShowDataFolder == canShowDataFolder &&
        other.canBatchOperation == canBatchOperation &&
        other.canAdd == canAdd &&
        other.canDelete == canDelete &&
        other.canUpdate == canUpdate &&
        other.canShare == canShare &&
        other.canReply == canReply;
  }

  @override
  int get hashCode {
    return Object.hash(
      canAddData,
      canAddDataFolder,
      canDelData,
      canDelDataFolder,
      canModifyDataFolder,
      canShowDataFolder,
      canBatchOperation,
      canAdd,
      canDelete,
      canUpdate,
      canShare,
      canReply,
    );
  }
}
