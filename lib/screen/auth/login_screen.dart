import 'package:flutter/material.dart';
import 'package:teststreetguard/screen/auth/signup_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../admin/admin_dashboard.dart';
import '../home/dashboard_screen.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? errorMessage;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> onSignIn() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    setState(() {
      errorMessage = null;
      _isLoading = true;
    });

    // ------------ ADMIN LOGIN ------------
    if (email == "admin@streetguard.com" && pass == "admin123") {
      await Future.delayed(const Duration(milliseconds: 800)); // Smooth feel
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
      return;
    }

    try {
      final url = Uri.parse("http://localhost:5000/api/auth/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": pass}),
      );

      final result = jsonDecode(response.body);

      if (result.containsKey("token")) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token']);
        await prefs.setString('userName', email.split('@').first);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              userName: email.split('@').first,
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage = result["message"] ?? "Login failed. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection error. Please check your network.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.background,
              AppColors.accent.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branding Section
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('StreetGuard', style: AppTextStyles.display),
                    const SizedBox(height: 8),
                    const Text(
                      'Community safety through smart reporting',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTextStyles.premiumCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome Back', style: AppTextStyles.title),
                          const SizedBox(height: 4),
                          const Text('Sign in to your account', style: AppTextStyles.subtitle),
                          const SizedBox(height: 32),

                          if (errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          CustomTextField(
                            label: 'Email Address',
                            hint: 'name@example.com',
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!isValidEmail(v)) return 'Invalid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            label: 'Password',
                            hint: '••••••••',
                            controller: passwordController,
                            obscure: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          CustomButton(
                            text: 'Sign In',
                            isLoading: _isLoading,
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                onSignIn();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Not a member?", style: AppTextStyles.body),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            );
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
