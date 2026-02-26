import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/utils/spiritual_utils.dart';

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
    final input = _emailCtrl.text.trim();
    final passwordInput = _passCtrl.text.trim();
    
    if (input.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Digite seu Email ou CPF.")));
       return;
    }

    setState(() => _isLoading = true);
    try {
      String email = input;
      String password = passwordInput.isEmpty ? "TUCPB" : passwordInput;

      // Check if input is CPF (only digits or formatted)
      final isCPF = RegExp(r'^\d+$').hasMatch(input.replaceAll(RegExp(r'[^\d]'), ''));
      
      if (isCPF) {
        final cpfRaw = input.replaceAll(RegExp(r'[^\d]'), '');
        // Search user by CPF in dadosPessoais.cpf
        final snap = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('dadosPessoais.cpf', isEqualTo: input) // Search with formatting if user typed it
            .get();
        
        var docs = snap.docs;
        if (docs.isEmpty) {
           // Try searching without formatting
           final snap2 = await FirebaseFirestore.instance
              .collection('usuarios')
              .where('dadosPessoais.cpf', isEqualTo: cpfRaw)
              .get();
           docs = snap2.docs;
        }

        if (docs.isEmpty) {
          throw "Usuário com CPF $input não encontrado.";
        }

        final userDoc = docs.first.data();
        email = userDoc['email'] ?? '';
        if (email.isEmpty) throw "Usuário encontrado mas sem email vinculado.";
        
        // --- RESTRICTION LOGIC ---
        final nameUpper = (userDoc['nome'] ?? userDoc['nomeCompleto'] ?? '').toString().toUpperCase();
        bool isAllowed = false;
        for (var allowed in ALLOWED_TABLET_USERS) {
           if (nameUpper.contains(allowed.toUpperCase())) {
             isAllowed = true;
             break;
           }
        }
        
        if (!isAllowed) {
           throw "Acesso não autorizado para o sistema Tablet.";
        }
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Let the router redirect based on auth state listener
      if (mounted) context.go('/admin'); // Default destination
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('invalid-credential')) msg = "Credenciais inválidas.";
        if (msg.contains('user-not-found')) msg = "Usuário não encontrado.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $msg"), backgroundColor: Colors.red));
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
            image: AssetImage('assets/images/kiosk_bg_selection.jpg'),
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
                   // color: Colors.transparent, // Removido background branco
                 ),
                 child: ClipOval(
                   child: Image.asset(
                     'assets/images/logo.png',
                     fit: BoxFit.cover, // Preenche o circulo
                     errorBuilder: (context, error, stackTrace) {
                       return const Icon(Icons.temple_buddhist, size: 80, color: Colors.brown);
                     },
                   ),
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
                   labelText: 'Email ou CPF', 
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   prefixIcon: const Icon(Icons.person, color: Colors.brown),
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
