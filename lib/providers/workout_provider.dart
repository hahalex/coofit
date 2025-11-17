import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/db_service.dart';

class WorkoutProvider with ChangeNotifier {
  final DBService _db = DBService();
  List<Workout> workouts = [];
  Map<int, List<Exercise>> exercises = {}; // workoutId -> list

  int userId;

  WorkoutProvider(this.userId);

  Future<void> loadWorkouts() async {
    final workoutMaps = await _db.getWorkoutsByUser(userId);
    workouts = workoutMaps
        .map(
          (e) => Workout(
            id: e['id'],
            userId: e['user_id'],
            dayOfWeek: e['day_of_week'].toString(),
            name: e['title'].toString(),
            description: e['description'].toString(),
          ),
        )
        .toList();

    exercises = {};
    for (var w in workouts) {
      final exerciseMaps = await _db.getExercisesByWorkout(w.id!);
      exercises[w.id!] = exerciseMaps
          .map(
            (e) => Exercise(
              id: e['id'],
              workoutId: e['workout_id'],
              name: e['title'].toString(),
              description: e['description'].toString(),
            ),
          )
          .toList();
    }
    notifyListeners();
  }

  Future<void> addWorkout(Workout w) async {
    await _db.insertWorkout({
      'user_id': w.userId,
      'day_of_week': w.dayOfWeek,
      'title': w.name,
      'description': w.description,
    });
    await loadWorkouts();
  }

  Future<void> updateWorkout(Workout w) async {
    await _db.updateWorkout(w.id!, {
      'day_of_week': w.dayOfWeek,
      'title': w.name,
      'description': w.description,
    });
    await loadWorkouts();
  }

  Future<void> addExercise(Exercise e) async {
    await _db.insertExercise({
      'workout_id': e.workoutId,
      'title': e.name,
      'description': e.description,
      'order_index': 0, // можно позже добавить сортировку
    });
    await loadWorkouts();
  }

  Future<void> updateExercise(Exercise e) async {
    await _db.updateExercise(e.id!, {
      'title': e.name,
      'description': e.description,
    });
    await loadWorkouts();
  }

  Future<void> deleteWorkout(int workoutId) async {
    await _db.deleteWorkout(workoutId); // вызываем метод из DBService
    await loadWorkouts(); // обновляем список после удаления
  }

  Future<void> deleteExercise(int exerciseId) async {
    await _db.deleteExercise(exerciseId); // вызываем метод из DBService
    await loadWorkouts(); // обновляем список после удаления
  }
}
