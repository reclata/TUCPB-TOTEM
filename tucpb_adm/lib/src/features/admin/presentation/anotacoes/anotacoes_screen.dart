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
    'GIRA DE ERE': ['ErÃª (CrianÃ§a)'],
    'GIRA DE PRETO VELHO': ['Preto Velho'],
    'GIRA DE BOIADEIRO': ['Boiadeiro', 'Marinheiro', 'Malandro (ZÃ© Pelintra)'],
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
          if (userId.isEmpty) return const Center(child: Text("UsuÃ¡rio nÃ£o logado (ID ausente)"));

          final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
          final isAssistencia = perfil.contains('assistencia') || perfil == 'pÃºblico' || perfil == 'visitante';

          if (isAssistencia) {
             return _AssistenciaAnotacoesView(userId: userId);
          }

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Minhas AnotaÃ§Ãµes & Fundamentos",
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
                        width: 320,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                      // FormulÃ¡rio de Detalhes
                      Expanded(
                        child: _AnotacaoForm(userId: userId, linha: _selectedLinha!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Erro ao carregar dados: $err")),
      ),
    );
  }
}

class _AnotacaoForm extends StatefulWidget {
  final String userId;
  final String linha;

  const _AnotacaoForm({required this.userId, required this.linha});

  @override
  State<_AnotacaoForm> createState() => _AnotacaoFormState();
}

class _AnotacaoFormState extends State<_AnotacaoForm> {
  final Map<String, TextEditingController> _controllers = {
    'cores': TextEditingController(),
    'velas': TextEditingController(),
    'observacao': TextEditingController(),
  };

  final Map<String, List<String>> _listFields = {
    'utiliza': [],
    'oferendas': [],
    'roupas': [],
  };

  List<Map<String, dynamic>> _checklist = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _monthlyDeliveries = [];
  bool _loading = false;
  bool _showMonthlyForm = false;
  String _selectedMonth = DateFormat('MMMM/yyyy', 'pt_BR').format(DateTime.now());

  @override
  void didUpdateWidget(_AnotacaoForm oldWidget) {
    if (oldWidget.linha != widget.linha) {
      _loadData();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final docRefs = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('anotacoes')
        .doc(widget.linha);

    if (widget.linha == 'Entrega Mensal') {
      final monthlySnap = await docRefs.collection('entregas').orderBy('timestamp', descending: true).get();
      _monthlyDeliveries = monthlySnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _loading = false;
      setState(() {});
      return;
    }

    final doc = await docRefs.get();

    if (doc.exists) {
      final data = doc.data()!;
      _controllers['cores']!.text = data['cores'] ?? '';
      _controllers['velas']!.text = data['velas'] ?? '';
      _controllers['observacao']!.text = data['observacao'] ?? '';
      
      _listFields['utiliza'] = List<String>.from(data['utiliza'] ?? (data['gosta'] != null ? [data['gosta']] : []));
      _listFields['oferendas'] = List<String>.from(data['oferendas'] ?? (data['come'] != null ? [data['come']] : []));
      _listFields['roupas'] = List<String>.from(data['roupas'] ?? (data['veste'] != null ? [data['veste']] : []));
      
      _checklist = List<Map<String, dynamic>>.from(data['checklist'] ?? []);
    } else {
      _controllers.values.forEach((c) => c.clear());
      _listFields.forEach((key, value) => value.clear());
      _checklist = [];
    }

    // Load history
    final historySnap = await docRefs.collection('historico').orderBy('timestamp', descending: true).limit(5).get();
    _history = historySnap.docs.map((d) => d.data()).toList();

    setState(() => _loading = false);
  }

  Future<void> _saveData() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final dataToSave = {
      'cores': _controllers['cores']!.text,
      'velas': _controllers['velas']!.text,
      'utiliza': _listFields['utiliza'],
      'oferendas': _listFields['oferendas'],
      'roupas': _listFields['roupas'],
      'observacao': _controllers['observacao']!.text,
      'dataReferencia': Timestamp.fromDate(now),
      'checklist': _checklist,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('anotacoes')
        .doc(widget.linha);

    if (widget.linha == 'Entrega Mensal') {
      await docRef.collection('entregas').add({
        ...dataToSave,
        'mes': _selectedMonth,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showMonthlyForm = false;
      // Also save to generic doc for general ref if needed, but the user wants cards
    } else {
      await docRef.set(dataToSave, SetOptions(merge: true));

      // Save to history
      await docRef.collection('historico').add({
        ...dataToSave,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AnotaÃ§Ãµes salvas com sucesso!"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              if (!_showMonthlyForm)
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.linha == 'Entrega Mensal') {
                      setState(() {
                        _showMonthlyForm = true;
                        _listFields.forEach((k, v) => v.clear());
                        _controllers.values.forEach((c) => c.clear());
                        _checklist = [];
                      });
                    } else {
                      _saveData();
                    }
                  },
                  icon: Icon(widget.linha == 'Entrega Mensal' ? Icons.add : Icons.save),
                  label: Text(widget.linha == 'Entrega Mensal' ? "NOVA ENTREGA" : "SALVAR DETALHES"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              if (_showMonthlyForm)
                 Row(
                   children: [
                     TextButton(onPressed: () => setState(() => _showMonthlyForm = false), child: const Text("CANCELAR")),
                     const SizedBox(width: 8),
                     ElevatedButton(
                       onPressed: _saveData, 
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                       child: const Text("SALVAR ENTREGA"),
                     ),
                   ],
                 ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.linha == 'Entrega Mensal' && !_showMonthlyForm)
            Expanded(
              child: _monthlyDeliveries.isEmpty 
                  ? const Center(child: Text("Nenhuma entrega mensal registrada."))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _monthlyDeliveries.length,
                      itemBuilder: (context, idx) => _buildMonthlyCard(_monthlyDeliveries[idx]),
                    ),
            ),
          if (_showMonthlyForm || widget.linha != 'Entrega Mensal')
          Expanded(
            child: ListView(
              children: [
                if (widget.linha == 'Entrega Mensal') ...[
                   const Text("MÃŠS DA ENTREGA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.primary)),
                   const SizedBox(height: 8),
                   _buildMonthPicker(),
                   const SizedBox(height: 24),
                ],
                _buildField("Cores principais", _controllers['cores']!, Icons.palette),
                _buildField("Velas utilizadas", _controllers['velas']!, Icons.light_mode),
                
                _buildDynamicList("O que utiliza", 'utiliza', Icons.favorite),
                _buildDynamicList("Oferendas e EbÃ³s", 'oferendas', Icons.restaurant),
                _buildDynamicList("Roupa usada nesta gira", 'roupas', Icons.checkroom),
                
                _buildField("ObservaÃ§Ãµes Adicionais", _controllers['observacao']!, Icons.notes),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  "Checklist (Itens para levar)",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._checklist.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      title: Text(item['item'] ?? ''),
                      value: item['checked'] ?? false,
                      onChanged: (v) => setState(() => _checklist[idx]['checked'] = v),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                        onPressed: () => setState(() => _checklist.removeAt(idx)),
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("ADICIONAR AO CHECKLIST"),
                ),
                
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text("HistÃ³rico de AnotaÃ§Ãµes", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._history.map((h) => _buildHistoryItem(h)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AdminTheme.primary),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          isExpanded: true,
          items: _generateMonths().map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _selectedMonth = v!),
        ),
      ),
    );
  }

  List<String> _generateMonths() {
    final List<String> months = [];
    final now = DateTime.now();
    for (int i = -6; i < 12; i++) {
        final date = DateTime(now.year, now.month + i, 1);
        months.add(DateFormat('MMMM/yyyy', 'pt_BR').format(date));
    }
    return months;
  }

  Widget _buildMonthlyCard(Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['mes'] ?? 'Sem MÃªs',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(widget.userId)
                        .collection('anotacoes')
                        .doc(widget.linha)
                        .collection('entregas')
                        .doc(data['id'])
                        .delete();
                    _loadData();
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildCompactInfo("Utiliza", (data['utiliza'] as List?)?.join(', ')),
                     _buildCompactInfo("Oferendas", (data['oferendas'] as List?)?.join(', ')),
                     _buildCompactInfo("Obs", data['observacao']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                   setState(() {
                      _showMonthlyForm = true;
                      _selectedMonth = data['mes'] ?? '';
                      _controllers['cores']!.text = data['cores'] ?? '';
                      _controllers['velas']!.text = data['velas'] ?? '';
                      _controllers['observacao']!.text = data['observacao'] ?? '';
                      _listFields['utiliza'] = List<String>.from(data['utiliza'] ?? []);
                      _listFields['oferendas'] = List<String>.from(data['oferendas'] ?? []);
                      _listFields['roupas'] = List<String>.from(data['roupas'] ?? []);
                      _checklist = List<Map<String, dynamic>>.from(data['checklist'] ?? []);
                   });
                },
                child: const Text("VER / EDITAR"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String label, String? text) {
    if (text == null || text.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: text),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDynamicList(String label, String fieldKey, IconData icon) {
    final list = _listFields[fieldKey]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.primary)),
        const SizedBox(height: 8),
        ...list.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => list[e.key] = v,
                  controller: TextEditingController(text: e.value)..selection = TextSelection.fromPosition(TextPosition(offset: e.value.length)),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, size: 18),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              IconButton(onPressed: () => setState(() => list.removeAt(e.key)), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
            ],
          ),
        )),
        TextButton.icon(
          onPressed: () => setState(() => list.add('')),
          icon: const Icon(Icons.add_circle_outline),
          label: Text("Adicionar $label"),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> data) {
    final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text("Salvo em ${DateFormat('dd/MM/yyyy HH:mm').format(date)}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHistoryText("Utiliza", (data['utiliza'] as List?)?.join(', ') ?? '-'),
                _buildHistoryText("Oferendas", (data['oferendas'] as List?)?.join(', ') ?? '-'),
                _buildHistoryText("Roupas", (data['roupas'] as List?)?.join(', ') ?? '-'),
                _buildHistoryText("ObservaÃ§Ã£o", data['observacao'] ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryText(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 12),
        children: [
          TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: text),
        ]
      )),
    );
  }

  void _addItemDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Item"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Nome do item"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _checklist.add({'item': controller.text, 'checked': false}));
                Navigator.pop(context);
              }
            },
            child: const Text("ADICIONAR"),
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
               error: (e, _) => Text("Erro ao carregar giras: `$e`"),
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
        .collection("usuarios")
        .doc(widget.userId)
        .collection("anotacoes_assistencia")
        .doc(widget.gira.id)
        .get();
    if (doc.exists) {
      if (mounted) {
        setState(() {
          _controller.text = doc.data()?["anotacao"] ?? "";
        });
      }
    }
  }

  Future<void> _saveNote() async {
    setState(() => _salvando = true);
    try {
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(widget.userId)
          .collection("anotacoes_assistencia")
          .doc(widget.gira.id)
          .set({
        "anotacao": _controller.text,
        "dataGira": widget.gira.data,
        "nomeGira": widget.gira.nome,
        "atualizadoEm": FieldValue.serverTimestamp(),
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anotação salva!")));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: `$e`"), backgroundColor: Colors.red));
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
                  DateFormat("dd/MM/yyyy").format(widget.gira.data),
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

