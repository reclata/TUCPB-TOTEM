import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'cobranca_model.dart';

final financeiroRepositoryProvider = Provider<FinanceiroRepository>((ref) {
  return FinanceiroRepository(FirebaseFirestore.instance);
});

final cobrancasStreamProvider = StreamProvider<List<CobrancaModel>>((ref) {
  return ref.watch(financeiroRepositoryProvider).cobrancasStream();
});

final cobrancasFiltradasProvider = StreamProvider<List<CobrancaModel>>((ref) {
  final userData = ref.watch(userDataProvider).asData?.value;
  final email = userData?['email'] ?? '';
  final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
  final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);

  return ref.watch(financeiroRepositoryProvider).cobrancasStream().map((list) {
    if (isAdmin) return list;
    return list.where((c) => c.usuarioEmail.toLowerCase() == email.toLowerCase()).toList();
  });
});

final cobrancasAvulsasStreamProvider = StreamProvider<List<CobrancaModel>>((ref) {
  return ref.watch(financeiroRepositoryProvider).cobrancasAvulsasStream();
});

final cobrancasAvulsasFiltradasProvider = StreamProvider<List<CobrancaModel>>((ref) {
  final userData = ref.watch(userDataProvider).asData?.value;
  final email = userData?['email'] ?? '';
  final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
  final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);

  return ref.watch(financeiroRepositoryProvider).cobrancasAvulsasStream().map((list) {
    if (isAdmin) return list;
    return list.where((c) => c.usuarioEmail.toLowerCase() == email.toLowerCase()).toList();
  });
});

// Provider da chave de API do ASAAS (salva localmente)
final asaasApiKeyProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('asaas_api_key');
});

class FinanceiroRepository {
  final FirebaseFirestore _db;
  static const _collection = 'cobrancas';

  FinanceiroRepository(this._db);

  Stream<List<CobrancaModel>> cobrancasStream() {
    return _db
        .collection(_collection)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CobrancaModel.fromFirestore).toList());
  }

  Stream<List<CobrancaModel>> cobrancasAvulsasStream() {
    // Busca tudo e filtra client-side para evitar índice composto
    return _db
        .collection(_collection)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map(CobrancaModel.fromFirestore)
            .where((c) => c.origem == OrigemCobranca.avulso)
            .toList());
  }

  Future<void> criarCobranca(CobrancaModel c) async {
    await _db.collection(_collection).add(c.toMap());
  }

  Future<void> atualizarStatus(String id, StatusCobranca status, {DateTime? dataPagamento}) async {
    final update = <String, dynamic>{'status': status.key};
    if (dataPagamento != null) update['dataPagamento'] = Timestamp.fromDate(dataPagamento);
    await _db.collection(_collection).doc(id).update(update);
  }

  Future<void> atualizarCobranca(String id, Map<String, dynamic> dados) async {
    await _db.collection(_collection).doc(id).update(dados);
  }

  Future<void> deletarCobranca(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  /// Totals para dashboard
  Future<Map<String, double>> calcularTotais() async {
    final snap = await _db.collection(_collection).get();
    double totalPago = 0;
    double totalAvulso = 0;
    double totalAsaas = 0;
    double totalPendente = 0;
    double totalAtrasado = 0;

    for (final doc in snap.docs) {
      final c = CobrancaModel.fromFirestore(doc);
      if (c.status == StatusCobranca.pago) {
        totalPago += c.valor;
        if (c.origem == OrigemCobranca.avulso) totalAvulso += c.valor;
        if (c.origem == OrigemCobranca.asaas) totalAsaas += c.valor;
      } else if (c.status == StatusCobranca.atrasado) {
        totalAtrasado += c.valor;
      } else {
        totalPendente += c.valor;
      }
    }

    return {
      'totalPago': totalPago,
      'totalAvulso': totalAvulso,
      'totalAsaas': totalAsaas,
      'totalPendente': totalPendente,
      'totalAtrasado': totalAtrasado,
    };
  }

  // Salvar API Key ASAAS localmente
  static Future<void> salvarAsaasKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('asaas_api_key', key);
  }

  static Future<String?> getAsaasKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('asaas_api_key');
  }
}
