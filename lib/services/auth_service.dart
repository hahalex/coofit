// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'db_service.dart';
import '../models/user.dart';

class AuthService {
  final DBService _db = DBService();

  // generate salt
  String _generateSalt([int length = 16]) {
    final r = Random.secure();
    final bytes = List<int>.generate(length, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  // PBKDF2 with HMAC-SHA256
  String _hashPassword(
    String password,
    String salt, {
    int iterations = 100000,
    int bits = 32,
  }) {
    final pass = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    final pbkdf2 = Pbkdf2(
      hashAlgorithm: sha256,
      iterations: iterations,
      bits: bits * 8,
    );
    final key = pbkdf2.process(pass, saltBytes);
    return base64Url.encode(key);
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    // basic frontend checks should be done in UI; here we'll also enforce
    if (username.trim().isEmpty) throw Exception('username required');
    if (email.trim().isEmpty) throw Exception('email required');
    if (password.isEmpty) throw Exception('password required');

    // unique checks
    final byUser = await _db.getUserByUsername(username);
    if (byUser != null) throw Exception('username_taken');

    final byEmail = await _db.getUserByEmail(email);
    if (byEmail != null) throw Exception('email_taken');

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.insertUser({
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': now,
    });

    // create default profile
    await _db.createProfile(id);

    final userMap = await _db.getUserById(id);
    return UserModel.fromMap(userMap!);
  }

  Future<UserModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    Map<String, dynamic>? userMap;

    if (usernameOrEmail.contains('@')) {
      userMap = await _db.getUserByEmail(usernameOrEmail);
    } else {
      userMap = await _db.getUserByUsername(usernameOrEmail);
    }

    if (userMap == null) throw Exception('user_not_found');

    final salt = userMap['salt'] as String;
    final storedHash = userMap['password_hash'] as String;
    final attemptHash = _hashPassword(password, salt);

    if (attemptHash != storedHash) throw Exception('invalid_credentials');

    return UserModel.fromMap(userMap);
  }
}

// Simple PBKDF2 implementation helper using package `crypto`
// The `Pbkdf2` class is not part of `crypto` top-level API; implement a small helper:
class Pbkdf2 {
  final Hash hashAlgorithm;
  final int iterations;
  final int bits;

  Pbkdf2({
    required this.hashAlgorithm,
    required this.iterations,
    required this.bits,
  });

  List<int> _hmac(List<int> key, List<int> data) {
    final hmac = Hmac(hashAlgorithm, key);
    return hmac.convert(data).bytes;
  }

  List<int> process(List<int> password, List<int> salt) {
    final blockCount = (bits / (hashAlgorithm.convert([]).bytes.length * 8))
        .ceil();
    final bytesPerBlock = hashAlgorithm.convert([]).bytes.length;
    var derived = <int>[];

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final blockIndexBytes = _int32(blockIndex);
      var u = _hmac(password, [...salt, ...blockIndexBytes]);
      var t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = _hmac(password, u);
        for (var j = 0; j < t.length; j++) t[j] ^= u[j];
      }
      derived.addAll(t);
    }

    return derived.sublist(0, bits ~/ 8);
  }

  List<int> _int32(int i) {
    return [(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff];
  }
}
