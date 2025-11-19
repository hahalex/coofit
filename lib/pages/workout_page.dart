import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/auth_provider.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).user!.id!;

    return ChangeNotifierProvider(
      create: (_) => WorkoutProvider(userId)..loadWorkouts(),
      child: const WorkoutPageContent(),
    );
  }
}

class WorkoutPageContent extends StatelessWidget {
  const WorkoutPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<WorkoutProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Workout',
          style: TextStyle(color: Color(0xFFDB0058), fontSize: 28),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: prov.workouts.length,
        itemBuilder: (ctx, idx) {
          final w = prov.workouts[idx];
          final exercises = prov.exercises[w.id!] ?? [];
          return Card(
            color: const Color(0xFF009999),
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                '${w.dayOfWeek}: ${w.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                w.description,
                style: const TextStyle(color: Colors.white),
              ),
              children: [
                ...exercises.map(
                  (e) => ListTile(
                    title: Text(
                      e.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      e.description,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFF232323)),
                      onPressed: () => prov.deleteExercise(e.id!),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showAddExerciseDialog(context, w.id!),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFC700),
                      ),
                      child: const Text('Add Exercise'),
                    ),
                    TextButton(
                      onPressed: () => prov.deleteWorkout(w.id!),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF232323),
                      ),
                      child: const Text('Delete Workout'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF009999),
        onPressed: () => _showAddWorkoutDialog(context, prov),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddWorkoutDialog(BuildContext context, WorkoutProvider prov) {
    final _key = GlobalKey<FormState>();
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    String day = 'Monday';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Workout',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF009999), width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: Form(
                  key: _key,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Add Workout',
                          style: TextStyle(
                            color: Color(0xFFFFC700),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: day,
                          items:
                              [
                                    'Monday',
                                    'Tuesday',
                                    'Wednesday',
                                    'Thursday',
                                    'Friday',
                                    'Saturday',
                                    'Sunday',
                                  ]
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => day = v!,
                          decoration: const InputDecoration(
                            labelText: 'Day of week',
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: nameCtl,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Workout Name',
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: descCtl,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFFDB0058)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (!_key.currentState!.validate()) return;
                                final w = Workout(
                                  userId: prov.userId,
                                  dayOfWeek: day,
                                  name: nameCtl.text,
                                  description: descCtl.text,
                                );
                                prov.addWorkout(w);
                                Navigator.of(ctx).pop();
                              },
                              child: const Text(
                                'Add',
                                style: TextStyle(color: Color(0xFFFFC700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddExerciseDialog(BuildContext context, int workoutId) {
    final _key = GlobalKey<FormState>();
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final prov = Provider.of<WorkoutProvider>(context, listen: false);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Exercise',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF009999), width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: Form(
                  key: _key,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Add Exercise',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFC700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameCtl,
                          decoration: const InputDecoration(
                            labelText: 'Exercise Name',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: descCtl,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFFDB0058)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (!_key.currentState!.validate()) return;
                                final e = Exercise(
                                  workoutId: workoutId,
                                  name: nameCtl.text,
                                  description: descCtl.text,
                                );
                                prov.addExercise(e);
                                Navigator.of(ctx).pop();
                              },
                              child: const Text(
                                'Add',
                                style: TextStyle(color: Color(0xFFFFC700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
