import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_log_model.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository(FirebaseFirestore.instance);
});

final activityLogsStreamProvider = StreamProvider<List<ActivityLogModel>>((ref) {
  return ref.watch(logRepositoryProvider).watchLogs();
});

class LogRepository {
  final FirebaseFirestore _db;
  static const _collection = 'activity_logs';

  LogRepository(this._db);

  Stream<List<ActivityLogModel>> watchLogs() {
    return _db
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map(ActivityLogModel.fromFirestore).toList());
  }

  Future<void> logAction({
    required String userId,
    required String userName,
    required String module,
    required LogActionType action,
    required String description,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final log = ActivityLogModel(
        id: '',
        userId: userId,
        userName: userName,
        module: module,
        action: action,
        description: description,
        timestamp: DateTime.now(),
        extraData: extraData,
      );
      await _db.collection(_collection).add(log.toMap());
    } catch (e) {
      print('Erro ao salvar log: $e');
    }
  }
}
