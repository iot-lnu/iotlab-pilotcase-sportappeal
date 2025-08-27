class User {
  final String id;
  final String username;
  final String email;
  final bool isAdmin;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.isAdmin = false,
    required this.createdAt,
  });

  // Convert from map (for database operations)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      isAdmin: map['isAdmin'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Convert to map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
