import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'gira_model.dart';

final girasRepositoryProvider = Provider<GirasRepository>((ref) {
  return GirasRepository(FirebaseFirestore.instance);
});

/// Stream de todas as giras ordenadas por data
final girasStreamProvider = StreamProvider<List<GiraModel>>((ref) {
  final userData = ref.watch(userDataProvider).asData?.value;
  final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
  final isAssistencia = perfil.contains('assistencia') || perfil == 'público' || perfil == 'visitante';
  return ref.watch(girasRepositoryProvider).girasStream(isAssistencia: isAssistencia);
});

/// Stream das giras de um mês específico
final girasPorMesProvider = StreamProvider.family<List<GiraModel>, DateTime>((ref, mes) {
  final userData = ref.watch(userDataProvider).asData?.value;
  final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
  final isAssistencia = perfil.contains('assistencia') || perfil == 'público' || perfil == 'visitante';
  return ref.watch(girasRepositoryProvider).girasPorMesStream(mes, isAssistencia: isAssistencia);
});

class GirasRepository {
  final FirebaseFirestore _db;
  static const _collection = 'giras';

  GirasRepository(this._db);

  Stream<List<GiraModel>> girasStream({bool isAssistencia = false}) {
    Query query = _db.collection(_collection).orderBy('data');
    if (isAssistencia) {
      query = query.where('visivelAssistencia', isEqualTo: true);
    }
    
    return query.snapshots().map((snap) {
          final firestoreGiras = snap.docs.map(GiraModel.fromFirestore).toList();
          final comemorativas = isAssistencia ? <GiraModel>[] : _getDatasComemorativas();
          final combined = [...firestoreGiras, ...comemorativas];
          combined.sort((a, b) => a.data.compareTo(b.data));
          return combined;
        });
  }

  Stream<List<GiraModel>> girasPorMesStream(DateTime mes, {bool isAssistencia = false}) {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fim = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    Query query = _db.collection(_collection)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(fim));
        
    if (isAssistencia) {
      query = query.where('visivelAssistencia', isEqualTo: true);
    }

    return query
        .orderBy('data')
        .snapshots()
        .map((snap) {
          final firestoreGiras = snap.docs.map(GiraModel.fromFirestore).toList();
          final comemorativas = isAssistencia 
              ? <GiraModel>[] 
              : _getDatasComemorativas()
                  .where((g) => g.data.year == mes.year && g.data.month == mes.month)
                  .toList();
          final combined = [...firestoreGiras, ...comemorativas];
          combined.sort((a, b) => a.data.compareTo(b.data));
          return combined;
        });
  }

  static List<GiraModel> _getDatasComemorativas() {
    final year = 2026; // Fixado para o ano atual solicitado
    return [
      // JANEIRO
      _com('01/01', "Confraternização universal", year, 1, 1),
      _com('06/01', "Dia de Reis", year, 1, 6),
      _com('20/01', "Sr. Oxóssi (São Sebastião)", year, 1, 20),
      
      // FEVEREIRO
      _com('17/02', "Carnaval", year, 2, 17),
      _com('18/02', "Início da Quaresma (Cinzas)", year, 2, 18),
      
      // MARÇO
      _com('21/03', "Dia Tradições Matrizes Africanas", year, 3, 21),
      _com('03/04', "Sexta-feira Santa", year, 4, 3), // Móvel 2026
      
      // ABRIL
      _com('05/04', "Páscoa", year, 4, 5), // Móvel 2026
      _com('23/04', "Sr. Ogum (São Jorge)", year, 4, 23),
      
      // MAIO
      _com('13/05', "Pretos Velhos (Abolição)", year, 5, 13),
      _com('24/05', "Santa Sarah & Maria da Cuia", year, 5, 24),
      _com('31/05', "Obá (Santa Joana D'Arc)", year, 5, 31),
      
      // JUNHO
      _com('13/06', "Xangô Menino (Sto Antônio)", year, 6, 13),
      _com('24/06', "Xangô Jovem (São João)", year, 6, 24),
      _com('29/06', "Xangô Agodô (São Pedro)", year, 6, 29),
      
      // JULHO
      _com('13/07', "Festa das Pomba-giras", year, 7, 13),
      _com('26/07', "Nanã Buruquê (Sant'Ana)", year, 7, 26),
      
      // AGOSTO
      _com('16/08', "Obaluaê (São Lázaro/Roque)", year, 8, 16),
      
      // SETEMBRO
      _com('27/09', "São Cosme, Damião e Doum", year, 9, 27),
      
      // OUTUBRO
      _com('05/10', "Ossãe (São Benedito)", year, 10, 5),
      _com('12/10', "Oxum (Nossa Sra Aparecida)", year, 10, 12),
      _com('31/10', "Feiticeiros", year, 10, 31),
      
      // NOVEMBRO
      _com('01/11', "Dia de todos os santos", year, 11, 1),
      _com('02/11', "Omolú (São Lázaro/Roque)", year, 11, 2),
      _com('15/11', "Dia Nacional da Umbanda", year, 11, 15),
      
      // DEZEMBRO
      _com('04/12', "Iansã (Santa Bárbara)", year, 12, 4),
      _com('08/12', "Iemanjá (Nossa Sra Conceição)", year, 12, 8),
      _com('13/12', "Ewá (Santa Luzia)", year, 12, 13),
      _com('27/12', "Homenagem à Maria da Cuia", year, 12, 27),
    ];
  }

  static GiraModel _com(String id, String nome, int y, int m, int d) {
    return GiraModel(
      id: "com-$id",
      nome: nome,
      data: DateTime(y, m, d),
      horarioInicio: "00:00",
      horarioFim: "23:59",
      ativo: true,
      tipo: 'comemorativa',
      cor: '#795548',
      descricao: "Data Comemorativa / Feriado Religioso",
    );
  }

  Future<void> criarGira(GiraModel gira) async {
    await _db.collection(_collection).add(gira.toMap());
  }

  Future<void> atualizarGira(String id, Map<String, dynamic> dados) async {
    await _db.collection(_collection).doc(id).update(dados);
  }

  Future<void> deletarGira(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Future<void> ativarDesativarGira(String id, bool ativo) async {
    await _db.collection(_collection).doc(id).update({'ativo': ativo});
  }
}
