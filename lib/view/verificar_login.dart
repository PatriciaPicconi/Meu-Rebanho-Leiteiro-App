import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'menuprincipal.dart';
import 'telalogin.dart';

class VerificarLogin extends StatelessWidget {
  const VerificarLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MenuPrincipal();
        }

        return const TelaLogin();
      },
    );
  }
}