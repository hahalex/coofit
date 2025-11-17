// lib/services/db_service.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'fitness_tracker.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        weight REAL,
        height REAL,
        daily_calories INTEGER DEFAULT 1500,
        water_glasses INTEGER DEFAULT 8,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT,
        description TEXT,
        day_of_week INTEGER,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        title TEXT,
        description TEXT,
        order_index INTEGER,
        FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE CASCADE
      );
    ''');
  }

  // --- Users CRUD ---
  Future<int> insertUser(Map<String, dynamic> userMap) async {
    final db = await database;
    return await db.insert('users', userMap);
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return res.first;
  }

  // --- Profiles ---
  Future<int> createProfile(int userId) async {
    final db = await database;
    return await db.insert('user_profiles', {
      'user_id': userId,
      'weight': null,
      'height': null,
      'daily_calories': 1500,
      'water_glasses': 8,
    });
  }

  Future<Map<String, dynamic>?> getProfileByUserId(int userId) async {
    final db = await database;
    final res = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<int> updateProfile(int userId, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update(
      'user_profiles',
      values,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // --- update user email ---
  Future<int> updateUserEmail(int userId, String newEmail) async {
    final db = await database;
    return await db.update(
      'users',
      {'email': newEmail},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // --- update user password/hash+salt ---
  Future<int> updateUserPassword(
    int userId,
    String newHash,
    String newSalt,
  ) async {
    final db = await database;
    return await db.update(
      'users',
      {'password_hash': newHash, 'salt': newSalt},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Generic update user (optional)
  Future<int> updateUserFields(int userId, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update(
      'users',
      values,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // --- Workouts ---
  Future<int> insertWorkout(Map<String, dynamic> workoutMap) async {
    final db = await database;
    return db.insert('workouts', workoutMap);
  }

  Future<List<Map<String, dynamic>>> getWorkoutsByUser(int userId) async {
    final db = await database;
    return db.query('workouts', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> updateWorkout(int workoutId, Map<String, dynamic> values) async {
    final db = await database;
    return db.update(
      'workouts',
      values,
      where: 'id = ?',
      whereArgs: [workoutId],
    );
  }

  Future<int> deleteWorkout(int workoutId) async {
    final db = await database;
    await db.delete(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    ); // удаляем упражнения
    return db.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
  }

  // --- Exercises ---
  Future<int> insertExercise(Map<String, dynamic> exerciseMap) async {
    final db = await database;
    return db.insert('exercises', exerciseMap);
  }

  Future<List<Map<String, dynamic>>> getExercisesByWorkout(
    int workoutId,
  ) async {
    final db = await database;
    return db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  Future<int> updateExercise(
    int exerciseId,
    Map<String, dynamic> values,
  ) async {
    final db = await database;
    return db.update(
      'exercises',
      values,
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }

  Future<int> deleteExercise(int exerciseId) async {
    final db = await database;
    return db.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
  }
}
