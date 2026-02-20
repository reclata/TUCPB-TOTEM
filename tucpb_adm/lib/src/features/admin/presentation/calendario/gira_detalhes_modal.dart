import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/gira_model.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';

class GiraDetalhesModal extends ConsumerStatefulWidget {
  final GiraModel gira;
  const GiraDetalhesModal({super.key, required this.gira});

  @override
  ConsumerState<GiraDetalhesModal> createState() => _GiraDetalhesModalState();
}

class _GiraDetalhesModalState extends ConsumerState<GiraDetalhesModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _linhas = [
    'Preto Velho', 'Caboclo', 'Erê (Criança)', 'Exu', 'Pombagira',
    'Baiano', 'Marinheiro', 'Boiadeiro', 'Cicano', 'Malandro (Zé Pelintra)',
    'Oriental', 'Cura / Caboclo das Sete Encruzilhadas',
    'Ogum', 'Oxóssi', 'Xangô', 'Iansã', 'Oxum', 'Iemanjá', 'Nanã',
    'Obaluaê / Omulu', 'Oxalá', 'Entrega / Mata'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String _detectarLinha() {
    final nome = widget.gira.nome.toLowerCase();
    for (final linha in _linhas) {
      if (nome.contains(linha.toLowerCase().split('(')[0].trim())) {
        return linha;
      }
    }
    return ''; // Nenhuma linha detectada automaticamente
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminTheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.gira.nome, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(
                          "${DateFormat('dd/MM/yyyy').format(widget.gira.data)} | ${widget.gira.horarioInicio} - ${widget.gira.horarioFim}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AdminTheme.primary,
              tabs: const [
                Tab(text: "Informações"),
                Tab(text: "Checklist & Fundamentos"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildChecklistTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _infoItem(Icons.description_outlined, "Descrição", widget.gira.descricao ?? "Sem descrição informada"),
        _infoItem(Icons.category_outlined, "Tipo de Evento", widget.gira.tipo.toUpperCase()),
        _infoItem(Icons.info_outline, "Status", widget.gira.ativo ? "Ativo / Programado" : "Cancelado / Bloqueado"),
        if (widget.gira.mediumNome != null && widget.gira.mediumNome!.isNotEmpty)
          _infoItem(Icons.person_outline, "Médium Responsável", widget.gira.mediumNome!),
        if (widget.gira.historico != null) ...[
          const Divider(height: 32),
          Text("RESUMO TOTEM", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          _infoItem(Icons.people_outline, "Total Atendimentos", "${widget.gira.historico!.totalAtendimentos}"),
          _infoItem(Icons.how_to_reg_outlined, "Médiuns Presentes", "${widget.gira.historico!.totalMediums}"),
        ],
      ],
    );
  }

  Widget _buildChecklistTab() {
    final userAsync = ref.watch(userDataProvider);
    final detectada = _detectarLinha();

    return userAsync.when(
      data: (userData) {
        final userId = userData?['docId'] ?? userData?['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
        if (detectada.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Não identificamos uma Linha específica para esta gira.", textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text("Abra a aba 'Anotações' para configurar seus fundamentos.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('anotacoes')
              .doc(detectada)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Nenhuma anotação para a linha: $detectada"));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final checklist = List<Map<String, dynamic>>.from(data['checklist'] ?? []);
            
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AdminTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("RESUMO DA LINHA ($detectada)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      _miniInfo("Velas", data['velas']),
                      _miniInfo("Cores", data['cores']),
                      _miniInfo("Levar", data['levar']),
                      _miniInfo("Data de Ref.", data['dataReferencia'] != null ? DateFormat('dd/MM/yyyy').format((data['dataReferencia'] as Timestamp).toDate()) : null),
                      _miniInfo("Observações", data['observacao']),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text("LISTA DE COMPRAS / PROVIDENCIAR", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                if (checklist.isEmpty) 
                  const Text("Nenhum item no checklist desta linha.", style: TextStyle(fontSize: 12, color: Colors.grey))
                else 
                  ...checklist.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return CheckboxListTile(
                      title: Text(item['item'], style: const TextStyle(fontSize: 14)),
                      value: item['checked'] ?? false,
                      dense: true,
                      onChanged: (v) {
                        checklist[idx]['checked'] = v;
                        FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(userId)
                          .collection('anotacoes')
                          .doc(detectada)
                          .update({'checklist': checklist});
                      },
                    );
                  }),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text("Erro ao carregar")),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AdminTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
