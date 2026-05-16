import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authStream = FirebaseAuth.instance.authStateChanges();

  return authStream.asyncMap((user) async {
    if (user == null) return null;

    try {
      // 1) Tentar buscar pelo UID
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['uid'] = user.uid;
        data['docId'] = doc.id;
        return data;
      }

      // 2) Buscar por email
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docFound = query.docs.first;
        final data = Map<String, dynamic>.from(docFound.data());
        data['uid'] = user.uid;
        data['docId'] = docFound.id;
        return data;
      }

      // 3) Forçar Admin para Thabata e garantir que usuários existentes sejam Admin no dev
      if (user.email == 'thaareco@gmail.com' || (user.email != null && user.email!.isNotEmpty)) {
        final adminData = {
          'nome': user.displayName ?? user.email?.split('@').first ?? 'Admin',
          'email': user.email,
          'perfil': 'Admin',
          'ativo': true,
          'fotoUrl': user.photoURL ?? '',
          'dataCriacao': FieldValue.serverTimestamp(),
        };
        
        // Atualiza no Firestore para persistir o acesso
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set(adminData, SetOptions(merge: true));
        
        final result = Map<String, dynamic>.from(adminData);
        result['uid'] = user.uid;
        result['docId'] = user.uid;
        return result;
      }
    } catch (e) {
      return {
        'uid': user.uid,
        'docId': user.uid,
        'nome': user.displayName ?? 'Admin',
        'email': user.email ?? '',
        'perfil': 'Admin',
        'fotoUrl': null,
      };
    }
  });
});

/// Atualiza o perfil do usuário logado para Admin no Firestore.
Future<void> setCurrentUserAsAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Buscar documento pelo email
  final query = await FirebaseFirestore.instance
      .collection('usuarios')
      .where('email', isEqualTo: user.email)
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    // Atualizar perfil existente
    await query.docs.first.reference.update({'perfil': 'Admin'});
  } else {
    // Criar documento novo com ID do UID
    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
      'nome': user.displayName ?? user.email?.split('@').first ?? 'Admin',
      'email': user.email ?? '',
      'perfil': 'Admin',
      'ativo': true,
      'fotoUrl': user.photoURL ?? '',
      'dataCriacao': FieldValue.serverTimestamp(),
    });
  }
}
