//شاشة تسجيل الدخول: lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../finance/finance_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = FinanceService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("يرجى إدخال البريد الإلكتروني وكلمة المرور");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _service.signIn(
        _emailController.text.trim(), 
        _passwordController.text.trim()
      );
      
      if (mounted && response.user != null) {
        // الانتقال للشاشة الرئيسية واستبدال شاشة الدخول في ذاكرة النظام
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showError("فشل تسجيل الدخول: تأكد من البيانات المدخلة");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance, size: 80, color: AppTheme.kDarkBrown),
                const SizedBox(height: 20),
                const Text(
                  "نظام مكعب ERP",
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: AppTheme.kDarkBrown
                  ),
                ),
                const SizedBox(height: 10),
                const Text("مرحباً بك، يرجى تسجيل الدخول", 
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 40),
                
                // حقل البريد الإلكتروني
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                // حقل كلمة المرور
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                
                // زر الدخول
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kDarkBrown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text(
                          "تسجيل الدخول", 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}