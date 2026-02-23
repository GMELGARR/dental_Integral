class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.isAdmin,
  });

  final String id;
  final String? email;
  final bool isAdmin;
}