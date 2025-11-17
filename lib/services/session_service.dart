// lib/services/session_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keyUserId = 'current_user_id';

  Future<void> saveUserId(int id) async {
    await _storage.write(key: _keyUserId, value: id.toString());
  }

  Future<int?> getUserId() async {
    final v = await _storage.read(key: _keyUserId);
    if (v == null) return null;
    return int.tryParse(v);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyUserId);
  }
}
