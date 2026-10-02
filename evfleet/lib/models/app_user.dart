class AppUser {
  final String uid;
  final String email;
  final String role; // 'admin' | 'operator'

  const AppUser({required this.uid, required this.email, required this.role});

  bool get isAdmin => role == 'admin';
  String get roleLabel => isAdmin ? 'Admin' : 'Operator';
}
