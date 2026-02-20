import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/presentation/widgets/novo_cadastro_dialog.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_modal_final.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class CadastrosScreen extends ConsumerStatefulWidget {
  const CadastrosScreen({super.key});

  @override
  ConsumerState<CadastrosScreen> createState() => _CadastrosScreenState();
}

class _CadastrosScreenState extends ConsumerState<CadastrosScreen> {
  // Filtros
  String _filterStatus = "Ativos"; // Ativos, Inativos, Todos
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirNovoCadastro() {
    showDialog(
      context: context,
      builder: (context) => const NovoCadastroModalFinal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construir Query
    Query query = FirebaseFirestore.instance.collection('usuarios');
    
    // Filtro simples no client-side para busca de texto (Firestore não tem LIKE %...%)
    // Filtro de Status pode ser no server se indexado, mas faremos client-side se volume for pequeno,
    // ou server-side se for exato. Por enquanto, client-side filtering é mais flexivel para MVP.

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Cadastros", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                    Text("Gerencie os membros da casa", style: TextStyle(color: AdminTheme.textSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const NovoCadastroModalFinal(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Novo Cadastro"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Filtros UI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.fromBorderSide(BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: "Buscar por nome...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AdminTheme.background,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AdminTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        items: ["Todos", "Ativos", "Inativos"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _filterStatus = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tabela Real
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Erro ao carregar dados: ${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Processar dados e filtros
                    var docs = snapshot.data!.docs;
                    
                    // Filtrar
                    var filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nome = (data['nome'] ?? '').toString().toLowerCase();
                      final ativo = data['ativo'] == true;
                      
                      bool matchesSearch = nome.contains(_searchQuery.toLowerCase());
                      bool matchesStatus = _filterStatus == "Todos" 
                          ? true 
                          : (_filterStatus == "Ativos" ? ativo : !ativo);
                          
                      return matchesSearch && matchesStatus;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text("Nenhum cadastro encontrado."));
                    }

                    return DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 24,
                      minWidth: 800,
                      headingRowColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.05)),
                      columns: [
                        const DataColumn2(label: Text("Nome"), size: ColumnSize.L),
                        const DataColumn(label: Text("Perfil")),
                        const DataColumn(label: Text("Data Entrada")),
                        if (_filterStatus == "Inativos" || _filterStatus == "Todos")
                          const DataColumn(label: Text("Data Saída")),
                        const DataColumn(label: Text("Status")),
                        const DataColumn2(label: Text("Ações"), fixedWidth: 200),
                      ],
                      rows: filteredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final bool isAtivo = data['ativo'] == true;
                        final String nome = data['nome'] ?? 'Sem Nome';
                        final String perfil = data['perfil'] ?? 'Membro';
                        final Timestamp? dtEntradaTs = data['dataEntrada'];
                        final String dtEntrada = dtEntradaTs != null 
                            ? DateFormat('dd/MM/yyyy').format(dtEntradaTs.toDate()) 
                            : '--';
                        final String dtSaida = '--'; // TODO: Implementar campo de saída no futuro

                        return DataRow(cells: [
                          DataCell(Text(nome, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(perfil)),
                          DataCell(Text(dtEntrada)),
                          if (_filterStatus == "Inativos" || _filterStatus == "Todos")
                            DataCell(Text(dtSaida)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                 color: isAtivo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isAtivo ? "Ativo" : "Inativo",
                                style: TextStyle(
                                  color: isAtivo ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.visibility, size: 20, color: Colors.blue), onPressed: () {}, tooltip: "Visualizar"),
                              IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.orange), onPressed: () {}, tooltip: "Editar"),
                              IconButton(icon: const Icon(FontAwesomeIcons.brazilianRealSign, size: 18, color: Colors.green), onPressed: () {}, tooltip: "Financeiro"),
                              IconButton(icon: const Icon(FontAwesomeIcons.fileLines, size: 18, color: Colors.brown), onPressed: () {}, tooltip: "Relatórios"),
                              IconButton(icon: const Icon(FontAwesomeIcons.clipboardCheck, size: 18, color: Colors.purple), onPressed: () {}, tooltip: "Obrigações"),
                            ],
                          )),
                        ]);
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
