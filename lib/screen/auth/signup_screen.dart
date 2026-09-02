import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:email_otp/email_otp.dart';
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final cnicController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool _isLoading = false;

  String? errorMessage;
  String passwordFeedback = "";

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    cnicController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  void formatCNIC(String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 13) digits = digits.substring(0, 13);

    String formatted = "";
    if (digits.length >= 5) {
      formatted = "${digits.substring(0, 5)}-${digits.substring(5)}";
    } else {
      formatted = digits;
    }
    if (digits.length >= 12) {
      formatted = "${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}";
    }

    cnicController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@(gmail\.com|yahoo\.com|outlook\.com|hotmail\.com)$').hasMatch(email);
  }

  String getPasswordStrength(String pass) {
    if (pass.length < 8) return "Min 8 characters required";
    if (!RegExp(r'[A-Z]').hasMatch(pass)) return "Include an uppercase letter";
    if (!RegExp(r'[0-9]').hasMatch(pass)) return "Include a number";
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) return "Include a special character";
    return "Strong password";
  }

  void _initiateSignup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final cnic = cnicController.text.trim();
    final phone = phoneController.text.trim();
    final pass = passwordController.text.trim();
    final confirm = confirmPassController.text.trim();

    setState(() => errorMessage = null);

    if (name.isEmpty || email.isEmpty || cnic.isEmpty || phone.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => errorMessage = "All fields are required.");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() => errorMessage = "Use a supported email (Gmail/Yahoo/etc).");
      return;
    }

    if (phone.length < 10 || phone.length > 15) {
      setState(() => errorMessage = "Please enter a valid contact number.");
      return;
    }

    if (pass != confirm) {
      setState(() => errorMessage = "Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otpResult = await ApiService.sendOtp(email, phone);
      
      if (mounted) setState(() => _isLoading = false);

      if (otpResult != null && otpResult['statusCode'] == 200) {
        if (mounted) _showOtpDialog(name, email, cnic, phone, pass);
      } else {
        final msg = otpResult?['message'] ?? "Failed to send OTP. Try again.";
        setState(() => errorMessage = msg);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      setState(() => errorMessage = "Error sending OTP: $e");
      print("OTP Error: $e");
    }
  }

  void _showOtpDialog(String name, String email, String cnic, String phone, String pass) {
    final emailOtpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text("Verification Required", style: AppTextStyles.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Enter the email verification code sent to $email.", style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "Email Verification Code",
                      hintText: "Enter Email OTP",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      counterText: "",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.secondary)),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () {
                    if (emailOtpController.text.length < 6) return;
                    
                    setDialogState(() => isVerifying = true);
                    
                    Navigator.pop(context); // Close dialog
                    _registerUser(name, email, cnic, phone, pass, emailOtpController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: isVerifying 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Verify", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _registerUser(String name, String email, String cnic, String phone, String pass, String emailOtp) async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("http://10.99.58.219:5000/api/auth/register");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": name,
          "cnic": cnic,
          "email": email,
          "password": pass,
          "phoneNumber": phone,
          "emailOtp": emailOtp,
          "role": "citizen"
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 201 || (result.containsKey("message") && result["message"] == "User registered successfully!")) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created successfully!"), backgroundColor: AppColors.success));
        Navigator.pop(context);
      } else {
        setState(() => errorMessage = result["message"] ?? "Registration failed.");
      }
    } catch (e) {
      setState(() => errorMessage = "Server connection lost. Try again later.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Hero(
                  tag: 'app_logo',
                  child: Icon(Icons.shield_outlined, size: 56, color: AppColors.accent),
                ),
                const SizedBox(height: 16),
                const Text("Create Account", style: AppTextStyles.display),
                const Text("Join the StreetGuard safety network", style: AppTextStyles.subtitle),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTextStyles.premiumCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(errorMessage!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(height: 20),
                      ],

                      CustomTextField(
                        label: "Full Name",
                        hint: "Ali Ahmed",
                        controller: nameController,
                        keyboardType: TextInputType.name,
                        maxLength: 30,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: "Email Address",
                        hint: "you@example.com",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: "Contact Number",
                        hint: "03001234567",
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 15,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: "CNIC",
                        hint: "XXXXX-XXXXXXX-X",
                        controller: cnicController,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => formatCNIC(v),
                        maxLength: 15,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: "Password",
                        hint: "••••••••",
                        controller: passwordController,
                        obscure: !passwordVisible,
                        onChanged: (v) => setState(() => passwordFeedback = getPasswordStrength(v)),
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.secondary, size: 20),
                          onPressed: () => setState(() => passwordVisible = !passwordVisible),
                        ),
                      ),
                      if (passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(passwordFeedback, style: TextStyle(color: passwordFeedback == "Strong password" ? AppColors.success : AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: "Confirm Password",
                        hint: "••••••••",
                        controller: confirmPassController,
                        obscure: !confirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(confirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.secondary, size: 20),
                          onPressed: () => setState(() => confirmPasswordVisible = !confirmPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: 32),

                      CustomButton(
                        text: "Create Account",
                        isLoading: _isLoading,
                        onPressed: _initiateSignup,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: AppTextStyles.body),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Sign In", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
