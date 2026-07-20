import 'package:flutter/material.dart';
import 'package:blue_cat_studio/features/auth/presentation/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlueCatStudioApp());
}

class BlueCatStudioApp extends StatelessWidget {
  const BlueCatStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blue Cat Studio Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Set your initial screen here
      home: const LoginScreen(),

      // Optional: Define named routes if you plan to navigate elsewhere later
      routes: {
        // '/dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}