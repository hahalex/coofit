// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/db_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  final AuthService _auth = AuthService();
  final SessionService _session = SessionService();
  final DBService _db = DBService();

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> tryAutoLogin() async {
    final id = await _session.getUserId();
    if (id != null) {
      final map = await _db.getUserById(id);
      if (map != null) {
        _user = UserModel.fromMap(map);
        notifyListeners();
      }
    }
  }

  Future<void> register(String username, String email, String password) async {
    final newUser = await _auth.register(
      username: username,
      email: email,
      password: password,
    );
    _user = newUser;
    await _session.saveUserId(newUser.id!);
    notifyListeners();
  }

  Future<void> login(String usernameOrEmail, String password) async {
    final found = await _auth.login(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );
    _user = found;
    await _session.saveUserId(found.id!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    await _session.clear();
    notifyListeners();
  }

  /// Change password wrapper — пробрасывает исключения выше
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) throw Exception('no_user');
    await _auth.changePassword(
      userId: _user!.id!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    // После смены пароля пользовательная запись в БД уже обновлена — можно перезагрузить пользователя:
    final map = await _db.getUserById(_user!.id!);
    if (map != null) {
      _user = UserModel.fromMap(map);
      notifyListeners();
    }
  }

  /// Change email wrapper
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    if (_user == null) throw Exception('no_user');
    await _auth.changeEmail(
      userId: _user!.id!,
      currentPassword: currentPassword,
      newEmail: newEmail,
    );
    // Обновим локальную модель
    final map = await _db.getUserById(_user!.id!);
    if (map != null) {
      _user = UserModel.fromMap(map);
      notifyListeners();
    }
  }
}
