import 'package:flutter/material.dart';
import 'package:teststreetguard/screen/auth/login_screen.dart';
import 'theme/app_colors.dart';


void main() {
  runApp(const StreetGuardApp());
}

class StreetGuardApp extends StatelessWidget {
  const StreetGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
      ),
      home: const LoginScreen(),
    );
  }
}
