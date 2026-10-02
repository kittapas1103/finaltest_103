import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthController.seeding,
      builder: (context, seeding, _) {
        return StreamBuilder<User?>(
          stream: AuthController.authChanges,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasData && !seeding) {
              return HomeScreen(user: snap.data!);
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
