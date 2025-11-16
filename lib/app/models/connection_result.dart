import 'connection_stage.dart';

class ConnectionResult {
  final bool success;
  final String message;
  final String? suggestion;
  final ConnectionStage? stage;

  ConnectionResult({
    required this.success,
    required this.message,
    this.suggestion,
    this.stage,
  });

  factory ConnectionResult.success(String message, {String? suggestion, ConnectionStage? stage}) {
    return ConnectionResult(
      success: true,
      message: message,
      suggestion: suggestion,
      stage: stage,
    );
  }

  factory ConnectionResult.failure(String message, {String? suggestion, ConnectionStage? stage}) {
    return ConnectionResult(
      success: false,
      message: message,
      suggestion: suggestion,
      stage: stage,
    );
  }
}
