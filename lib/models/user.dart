// lib/models/user.dart
class UserModel {
  final int? id;
  final String username;
  final String email;
  final String passwordHash; // хэш
  final String salt;
  final int createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'] as int?,
    username: m['username'] as String,
    email: m['email'] as String,
    passwordHash: m['password_hash'] as String,
    salt: m['salt'] as String,
    createdAt: m['created_at'] as int,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'email': email,
    'password_hash': passwordHash,
    'salt': salt,
    'created_at': createdAt,
  };
}
