class AppUser {
  final String userId;
  final String email;
  final String name;
  final DateTime createdAt;

  AppUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory AppUser.fromCognito(Map<String, String> attrs) {
    return AppUser(
      userId: attrs['sub']!,
      email: attrs['email']!,
      name: attrs['name'] ?? '',
      createdAt:
          DateTime.now(), // Cognito doesn't expose creation date directly
    );
  }
}
