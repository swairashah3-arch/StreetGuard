import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:email_otp/email_otp.dart';
import 'package:teststreetguard/screen/auth/login_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  EmailOTP.config(
    appName: 'StreetGuard',
    otpType: OTPType.numeric,
    emailTheme: EmailTheme.v1,
  );
  
  EmailOTP.setSMTP(
    host: 'smtp.gmail.com',
    emailPort: EmailPort.port587,
    secureType: SecureType.tls,
    username: dotenv.env['SMTP_EMAIL'] ?? '',
    password: dotenv.env['SMTP_PASSWORD'] ?? '',
  );

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
