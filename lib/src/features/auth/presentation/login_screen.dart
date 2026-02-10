
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      // Let the router redirect based on auth state listener
      if (mounted) context.go('/admin'); // Default destination
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text("TERREIRO SYSTEM", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
               const SizedBox(height: 10),
               TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
               const SizedBox(height: 20),
               if (_isLoading) const CircularProgressIndicator()
               else ElevatedButton(onPressed: _login, child: const Text("ENTRAR")),
               
               const SizedBox(height: 20),
               // Shortcut for Kiosk/TV (usually these would be separate apps or routed after login)
               // For demo, we might want direct access buttons if no auth required?
               // But prompt says 'Login por Firebase Auth'.
            ],
          ),
        ),
      ),
    );
  }
}
