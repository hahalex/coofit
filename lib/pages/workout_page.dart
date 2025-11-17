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
      appBar: AppBar(title: const Text('Workouts')),
      body: ListView.builder(
        itemCount: prov.workouts.length,
        itemBuilder: (ctx, idx) {
          final w = prov.workouts[idx];
          final exercises = prov.exercises[w.id!] ?? [];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text('${w.dayOfWeek}: ${w.name}'),
              subtitle: Text(w.description),
              children: [
                ...exercises.map(
                  (e) => ListTile(
                    title: Text(e.name),
                    subtitle: Text(e.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => prov.deleteExercise(e.id!),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showAddExerciseDialog(context, w.id!),
                      child: const Text('Add Exercise'),
                    ),
                    TextButton(
                      onPressed: () => prov.deleteWorkout(w.id!),
                      child: const Text(
                        'Delete Workout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkoutDialog(context, prov),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddWorkoutDialog(BuildContext context, WorkoutProvider prov) {
    final _key = GlobalKey<FormState>();
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    String day = 'Monday';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Workout'),
        content: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                  onChanged: (v) => day = v!,
                  decoration: const InputDecoration(labelText: 'Day of week'),
                ),
                TextFormField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Workout Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: descCtl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, int workoutId) {
    final _key = GlobalKey<FormState>();
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final prov = Provider.of<WorkoutProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Exercise'),
        content: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Exercise Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: descCtl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
