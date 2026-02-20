import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'news_model.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(FirebaseFirestore.instance);
});

final newsStreamProvider = StreamProvider<List<Noticia>>((ref) {
  final userData = ref.watch(userDataProvider).asData?.value;
  final perfil = (userData?['perfil'] ?? '').toString();
  final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil.toLowerCase());
  
  return ref.watch(newsRepositoryProvider).streamNoticias().map((list) {
    if (isAdmin) return list;
    return list.where((n) {
      if (n.visibilidade == VisibilidadeNoticia.todos) return true;
      if (n.visibilidade == VisibilidadeNoticia.perfis) {
         return n.perfisPermitidos.any((p) => p.toLowerCase() == perfil.toLowerCase());
      }
      return false;
    }).toList();
  });
});

final newsAdminStreamProvider = StreamProvider<List<Noticia>>((ref) {
  return ref.watch(newsRepositoryProvider).streamNoticiasAdmin();
});

final newsDestaquesProvider = StreamProvider<List<Noticia>>((ref) {
  return ref.watch(newsRepositoryProvider).streamDestaques();
});

class NewsRepository {
  final FirebaseFirestore _db;
  static const _coll = 'news';

  NewsRepository(this._db);

  Stream<List<Noticia>> streamNoticias() {
    return _db
        .collection(_coll)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map(Noticia.fromFirestore)
            .where((n) => n.isPublicada && !n.isArquivada)
            .toList());
  }

  Stream<List<Noticia>> streamNoticiasAdmin() {
    return _db
        .collection(_coll)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Noticia.fromFirestore).toList());
  }

  Stream<List<Noticia>> streamDestaques() {
    return _db
        .collection(_coll)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map(Noticia.fromFirestore)
            .where((n) => n.isPublicada && !n.isArquivada && n.isDestaque)
            .toList());
  }

  Future<void> criarNoticia(Noticia noticia) async {
    await _db.collection(_coll).add(noticia.toMap());
  }

  Future<void> atualizarNoticia(String id, Map<String, dynamic> data) async {
    await _db.collection(_coll).doc(id).update(data);
  }

  Future<void> deletarNoticia(String id) async {
    await _db.collection(_coll).doc(id).delete();
  }
}
