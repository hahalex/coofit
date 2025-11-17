class Workout {
  int? id;
  int userId;
  String dayOfWeek; // например "Monday", "Tuesday" ...
  String name;
  String description;

  Workout({
    this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'day_of_week': dayOfWeek,
      'name': name,
      'description': description,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      userId: map['user_id'],
      dayOfWeek: map['day_of_week'],
      name: map['name'],
      description: map['description'],
    );
  }
}
