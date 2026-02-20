import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'package:tucpb_adm/src/features/admin/data/gira_model.dart';
import 'package:tucpb_adm/src/features/admin/data/giras_repository.dart';

class AnotacoesScreen extends ConsumerStatefulWidget {
  const AnotacoesScreen({super.key});

  @override
  ConsumerState<AnotacoesScreen> createState() => _AnotacoesScreenState();
}

class _AnotacoesScreenState extends ConsumerState<AnotacoesScreen> {
  final Map<String, List<String>> _giras = {
    'GIRA DE CABOCLO': ['Caboclo'],
    'GIRA DE ERE': ['Erê (Criança)'],
    'GIRA DE PRETO VELHO': ['Preto Velho'],
    'GIRA DE BOIADEIRO': ['Boiadeiro', 'Marinheiro', 'Malandro (Zé Pelintra)'],
    'GIRA DE CIGANO': ['Cicano'],
    'GIRA DE BAIANO': ['Baiano'],
    'GIRA DE ESQUERDA': ['Pombagira', 'Exu', 'Exu Mirim', 'Feiticeiro'],
    'GIRA DE FEITICEIRO': ['Feiticeiro'],
    'ENTREGAS': ['Entrega Mensal', 'Entrega Fim de Ano'],
  };

  String? _selectedLinha;

  @override
  void initState() {
    super.initState();
    _selectedLinha = 'Caboclo';
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: userAsync.when(
        data: (userData) {
          final userId = userData?['docId'] ?? userData?['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          if (userId.isEmpty) return const Center(child: Text("Usuário não logado (ID ausente)"));

          final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
          final isAssistencia = perfil.contains('assistencia') || perfil == 'público' || perfil == 'visitante';

          if (isAssistencia) {
             return _AssistenciaAnotacoesView(userId: userId);
          }

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Minhas Anotações & Fundamentos",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Registre os detalhes de cada linha de trabalho para seu desenvolvimento",
                  style: GoogleFonts.outfit(fontSize: 16, color: AdminTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar de Linhas
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: _giras.entries.map((gira) {
                            return ExpansionTile(
                              title: Text(
                                gira.key,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AdminTheme.textPrimary,
                                ),
                              ),
                              initiallyExpanded: gira.value.contains(_selectedLinha),
                              children: gira.value.map((linha) {
                                final isSelected = _selectedLinha == linha;
                                return ListTile(
                                  selected: isSelected,
                                  dense: true,
                                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                                  selectedTileColor: AdminTheme.primary.withOpacity(0.05),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  title: Text(
                                    linha,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AdminTheme.primary : AdminTheme.textPrimary,
                                    ),
                                  ),
                                  onTap: () => setState(() => _selectedLinha = linha),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Área de Conteúdo
                      Expanded(
                        child: _selectedLinha == null
                            ? const Center(child: Text("Selecione uma linha para ver as anotações"))
                            : _LinhaAnotacoesContent(userId: userId, linha: _selectedLinha!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erro: $e")),
      ),
    );
  }
}

class _LinhaAnotacoesContent extends StatefulWidget {
  final String userId;
  final String linha;
  const _LinhaAnotacoesContent({required this.userId, required this.linha});

  @override
  State<_LinhaAnotacoesContent> createState() => _LinhaAnotacoesContentState();
}

class _LinhaAnotacoesContentState extends State<_LinhaAnotacoesContent> {
  final _anotacaoController = TextEditingController();
  bool _salvando = false;

  @override
  void didUpdateWidget(_LinhaAnotacoesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linha != widget.linha) {
      _loadAnotacao();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAnotacao();
  }

  Future<void> _loadAnotacao() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('anotacoes')
        .doc(widget.linha)
        .get();
    
    if (doc.exists) {
      _anotacaoController.text = doc.data()?['conteudo'] ?? '';
    } else {
      _anotacaoController.text = '';
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('anotacoes')
        .doc(widget.linha)
        .set({
      'conteudo': _anotacaoController.text,
      'ultimaAtualizacao': FieldValue.serverTimestamp(),
    });
    setState(() => _salvando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anotação salva com sucesso!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.linha,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: const Text("SALVAR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Expanded(
            child: TextField(
              controller: _anotacaoController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: "Escreva aqui os fundamentos, ervas, guias, pontos e observações desta linha...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: GoogleFonts.outfit(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistenciaAnotacoesView extends ConsumerWidget {
  final String userId;
  const _AssistenciaAnotacoesView({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final girasAsync = ref.watch(girasStreamProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("Minhas Anotações por Gira", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           const Text("Registre suas percepções e sentimentos de cada gira assistida"),
           const SizedBox(height: 24),
           Expanded(
             child: girasAsync.when(
               data: (giras) {
                 final passadas = giras.where((g) => g.data.isBefore(DateTime.now().add(const Duration(days: 1)))).toList().reversed.toList();
                 if (passadas.isEmpty) {
                   return const Center(child: Text("Nenhuma gira visível para anotações no momento."));
                 }
                 return ListView.builder(
                   itemCount: passadas.length,
                   itemBuilder: (context, index) {
                     final gira = passadas[index];
                     return _GiraAnotacaoCard(userId: userId, gira: gira);
                   },
                 );
               },
               loading: () => const Center(child: CircularProgressIndicator()),
               error: (e, _) => Text("Erro ao carregar giras: $e"),
             ),
           ),
        ],
      ),
    );
  }
}

class _GiraAnotacaoCard extends StatefulWidget {
  final String userId;
  final GiraModel gira;
  const _GiraAnotacaoCard({required this.userId, required this.gira});

  @override
  State<_GiraAnotacaoCard> createState() => _GiraAnotacaoCardState();
}

class _GiraAnotacaoCardState extends State<_GiraAnotacaoCard> {
  final _controller = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('anotacoes_assistencia')
        .doc(widget.gira.id)
        .get();
    if (doc.exists) {
      if (mounted) {
        setState(() {
          _controller.text = doc.data()?['anotacao'] ?? '';
        });
      }
    }
  }

  Future<void> _saveNote() async {
    setState(() => _salvando = true);
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('anotacoes_assistencia')
          .doc(widget.gira.id)
          .set({
        'anotacao': _controller.text,
        'dataGira': widget.gira.data,
        'nomeGira': widget.gira.nome,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anotação salva!")));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.calendarDay, size: 16, color: AdminTheme.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(widget.gira.data),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.gira.nome, style: GoogleFonts.outfit(fontSize: 16, color: AdminTheme.textSecondary))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Sua anotação sobre esta gira...",
                hintStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _saveNote,
                icon: _salvando 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 16),
                label: Text(_salvando ? "Salvando..." : "Salvar Anotação"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
