import 'package:cloud_firestore/cloud_firestore.dart';

enum LogActionType {
  create,
  update,
  delete,
  other
}

class ActivityLogModel {
  final String id;
  final String userId;
  final String userName;
  final String module; // e.g., 'estoque', 'financeiro', 'usuarios', 'calendario'
  final LogActionType action;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? extraData;

  ActivityLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.module,
    required this.action,
    required this.description,
    required this.timestamp,
    this.extraData,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Desconhecido',
      module: data['module'] ?? 'Geral',
      action: LogActionType.values.firstWhere(
        (e) => e.name == data['action'],
        orElse: () => LogActionType.other,
      ),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      extraData: data['extraData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'module': module,
      'action': action.name,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'extraData': extraData,
    };
  }
}
