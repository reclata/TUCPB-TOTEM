
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Digite seu email para redefinir a senha.")));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email de redefinição enviado! Verifique sua caixa de entrada.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao enviar email: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wood_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 // LOGO
                 Container(
                 height: 150,
                 width: 150,
                 decoration: const BoxDecoration(
                   shape: BoxShape.circle,
                   color: Colors.white,
                 ),
                 child: Image.asset(
                   'assets/images/logo.jpg',
                   fit: BoxFit.contain,
                   errorBuilder: (context, error, stackTrace) {
                     return const Icon(Icons.temple_buddhist, size: 80, color: Colors.brown);
                   },
                 ),
               ),
                const SizedBox(height: 20),
                Text(
                  "T.U.C.P.B.", 
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown[800])
                ),
                Text(
                  "Token System", 
                  style: GoogleFonts.outfit(fontSize: 18, color: Colors.brown[600], letterSpacing: 1.2)
                ),
                const SizedBox(height: 40),
               TextField(
                 controller: _emailCtrl, 
                 decoration: InputDecoration(
                   labelText: 'Email', 
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   prefixIcon: const Icon(Icons.email, color: Colors.brown),
                 ),
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: _passCtrl, 
                 decoration: InputDecoration(
                   labelText: 'Senha',
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                   suffixIcon: IconButton(
                     icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.brown),
                     onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                   ),
                 ), 
                 obscureText: _obscurePassword,
               ),
               const SizedBox(height: 10),
               Align(
                 alignment: Alignment.centerRight,
                 child: TextButton(
                   onPressed: _resetPassword,
                   child: Text("Esqueci minha senha", style: TextStyle(color: Colors.brown[600])),
                 ),
               ),
               const SizedBox(height: 24),
               if (_isLoading) const CircularProgressIndicator(color: Colors.brown)
               else SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.brown,
                     foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   onPressed: _login, 
                   child: const Text("ENTRAR", style: TextStyle(fontSize: 16)),
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
