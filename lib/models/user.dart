class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String authProvider; // 'google', 'facebook', 'instagram', etc.
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.authProvider,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      authProvider: json['authProvider'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 