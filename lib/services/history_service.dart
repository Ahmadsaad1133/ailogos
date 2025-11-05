import '../models/generation_record.dart';
import 'user_data_store.dart';
class HistoryService {
  HistoryService(this._store);

  final UserDataStore _store;

  Future<List<GenerationRecord>> loadHistory() {
    return _store.fetchHistory();
  }
  Stream<List<GenerationRecord>> get historyStream => _store.historyStream;

  Future<void> addRecord(GenerationRecord record) {
    return _store.upsertHistoryRecord(record);
  }

  Future<void> clearHistory() {
    return _store.clearHistory();
  }
}