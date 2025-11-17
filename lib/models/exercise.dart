class Exercise {
  int? id;
  int workoutId;
  String name;
  String description;

  Exercise({
    this.id,
    required this.workoutId,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'name': name,
      'description': description,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      workoutId: map['workout_id'],
      name: map['name'],
      description: map['description'],
    );
  }
}
