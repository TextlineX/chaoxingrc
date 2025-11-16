enum ConnectionStage {
  networkCheck,
  tcpConnection,
  apiEndpoint,
  unknown,
}

extension ConnectionStageExtension on ConnectionStage {
  String get description {
    switch (this) {
      case ConnectionStage.networkCheck:
        return '网络检查';
      case ConnectionStage.tcpConnection:
        return 'TCP连接';
      case ConnectionStage.apiEndpoint:
        return 'API端点';
      case ConnectionStage.unknown:
        return '未知阶段';
    }
  }
}
