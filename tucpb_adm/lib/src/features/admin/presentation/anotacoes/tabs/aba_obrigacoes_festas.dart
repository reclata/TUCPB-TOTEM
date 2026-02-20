import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AbaObrigacoesFestas extends ConsumerStatefulWidget {
  const AbaObrigacoesFestas({super.key});

  @override
  ConsumerState<AbaObrigacoesFestas> createState() => _AbaObrigacoesFestasState();
}

class _AbaObrigacoesFestasState extends ConsumerState<AbaObrigacoesFestas> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AdminTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AdminTheme.primary,
          tabs: const [
            Tab(text: "OBRIGAÇÕES"),
            Tab(text: "FESTAS"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const _ListaObrigacoes(),
              const _ListaFestas(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListaObrigacoes extends ConsumerWidget {
  const _ListaObrigacoes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Registro de Obrigações", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _abrirFormObrigacao(context),
                icon: const Icon(Icons.add),
                label: const Text("NOVA OBRIGAÇÃO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('obrigacoes').orderBy('data', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhuma obrigação registrada."));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['data'] as Timestamp?)?.toDate();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(data['mediumNome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${data['tipoObrigacao'] ?? ''} - ${date != null ? DateFormat('dd/MM/yyyy').format(date) : ''}"),
                      trailing: Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(data['valor'] ?? 0), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      onTap: () => _abrirFormObrigacao(context, doc: doc),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _abrirFormObrigacao(BuildContext context, {DocumentSnapshot? doc}) {
    showDialog(
      context: context,
      builder: (context) => _FormObrigacaoModal(doc: doc),
    );
  }
}

class _FormObrigacaoModal extends ConsumerStatefulWidget {
  final DocumentSnapshot? doc;
  const _FormObrigacaoModal({this.doc});

  @override
  ConsumerState<_FormObrigacaoModal> createState() => _FormObrigacaoModalState();
}

class _FormObrigacaoModalState extends ConsumerState<_FormObrigacaoModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMediumId;
  String? _selectedMediumNome;
  String _tipoPerfil = 'Médium'; // Médium ou Orixá
  String? _selectedOrixa;
  DateTime _data = DateTime.now();
  final _valorController = TextEditingController();
  String _metodoPagamento = 'À vista';
  int _parcelas = 1;
  List<Map<String, dynamic>> _pagamentos = [];
  List<Map<String, dynamic>> _listaCompras = [];
  List<Map<String, dynamic>> _comidasRonco = [];
  List<Map<String, dynamic>> _comidasConga = [];
  
  // Orixá specifics
  List<String> _participantesBanhoId = [];
  final _custoErvaController = TextEditingController();

  final List<String> _orixas = ['Oxóssi', 'Ossae', 'Ogum', 'Xangô', 'Nanã', 'Iansã', 'Omolu', 'Obaluaê', 'Iemanjá', 'Oxum', 'Obá', 'Ewá'];

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _selectedMediumId = data['mediumId'];
      _selectedMediumNome = data['mediumNome'];
      _tipoPerfil = data['tipoObrigacao'] ?? 'Médium';
      _selectedOrixa = data['orixa'];
      _data = (data['data'] as Timestamp).toDate();
      _valorController.text = (data['valor'] ?? 0).toString();
      _metodoPagamento = data['metodoPagamento'] ?? 'À vista';
      _parcelas = data['parcelas'] ?? 1;
      _pagamentos = List<Map<String, dynamic>>.from(data['pagamentos_detalhe'] ?? []);
      _listaCompras = List<Map<String, dynamic>>.from(data['listaCompras'] ?? []);
      _comidasRonco = List<Map<String, dynamic>>.from(data['comidasRonco'] ?? []);
      _comidasConga = List<Map<String, dynamic>>.from(data['comidasConga'] ?? []);
      _participantesBanhoId = List<String>.from(data['participantesBanhoId'] ?? []);
      _custoErvaController.text = (data['custoErvas'] ?? 0).toString();
    } else {
      _atualizarParcelas();
    }
  }

  void _atualizarParcelas() {
    final valorTotal = double.tryParse(_valorController.text) ?? 0;
    final valorParcela = valorTotal / _parcelas;
    _pagamentos = List.generate(_parcelas, (i) => {
      'numero': i + 1,
      'data': DateTime(_data.year, _data.month + i, _data.day),
      'valor': valorParcela,
      'pago': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1000,
        height: 800,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Formulário de Obrigação", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seleção de Médium e Tipo
                      Row(
                        children: [
                          Expanded(
                            child: _buildMediumDropdown(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _tipoPerfil,
                              decoration: const InputDecoration(labelText: "Tipo de Obrigação", border: OutlineInputBorder()),
                              items: ['Médium', 'Orixá'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _tipoPerfil = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Data e Valor
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: _data, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                if (d != null) setState(() => _data = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: "Data da Obrigação", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                                child: Text(DateFormat('dd/MM/yyyy').format(_data)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _valorController,
                              decoration: const InputDecoration(labelText: "Valor Total (R$)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() => _atualizarParcelas()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_tipoPerfil == 'Orixá') ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedOrixa,
                                decoration: const InputDecoration(labelText: "Orixá", border: OutlineInputBorder()),
                                items: _orixas.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                onChanged: (v) => setState(() => _selectedOrixa = v),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: const SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSecaoBanho(),
                        const SizedBox(height: 24),
                      ],

                      _buildPagamentoSection(),
                      const SizedBox(height: 24),
                      
                      if (_tipoPerfil == 'Médium') ...[
                        _buildListaComprasSection(),
                        const SizedBox(height: 24),
                      ],

                      _buildComidasRoncoSection(),
                      const SizedBox(height: 24),
                      _buildComidasCongaSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                    child: const Text("SALVAR OBRIGAÇÃO"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediumDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').orderBy('nome').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final users = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          value: _selectedMediumId,
          decoration: const InputDecoration(labelText: "Selecionar Médium", border: OutlineInputBorder()),
          items: users.map((u) {
            final d = u.data() as Map<String, dynamic>;
            return DropdownMenuItem(value: u.id, child: Text(d['nome'] ?? ''));
          }).toList(),
          onChanged: (v) {
            final u = users.firstWhere((element) => element.id == v);
            setState(() {
              _selectedMediumId = v;
              _selectedMediumNome = (u.data() as Map<String, dynamic>)['nome'];
            });
          },
        );
      },
    );
  }

  Widget _buildSecaoBanho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DETALHES DO BANHO", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _custoErvaController,
                decoration: const InputDecoration(labelText: "Custo de Ervas por Médium (R$)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
        if (_participantesBanhoId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Total do Banho: ${NumberFormat.simpleCurrency(locale: 'pt_BR').format((double.tryParse(_custoErvaController.text) ?? 0) * _participantesBanhoId.length)}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        const SizedBox(height: 12),
        const Text("Médiuns Participantes do Banho:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').orderBy('nome').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            return Wrap(
              spacing: 8,
              children: snapshot.data!.docs.map((u) {
                final d = u.data() as Map<String, dynamic>;
                final isSelected = _participantesBanhoId.contains(u.id);
                return FilterChip(
                  label: Text(d['nome'] ?? '', style: const TextStyle(fontSize: 10)),
                  selected: isSelected,
                  onSelected: (v) {
                    setState(() {
                      if (v) _participantesBanhoId.add(u.id);
                      else _participantesBanhoId.remove(u.id);
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPagamentoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text("FINANCEIRO", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
         const SizedBox(height: 12),
         Row(
           children: [
             Expanded(
               child: DropdownButtonFormField<String>(
                 value: _metodoPagamento,
                 decoration: const InputDecoration(labelText: "Forma de Pagamento", border: OutlineInputBorder()),
                 items: ['À vista', 'Parcelado'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                 onChanged: (v) => setState(() {
                    _metodoPagamento = v!;
                    if (v == 'À vista') _parcelas = 1;
                    _atualizarParcelas();
                 }),
               ),
             ),
             const SizedBox(width: 16),
             if (_metodoPagamento == 'Parcelado')
                Expanded(
                  child: Row(
                    children: [
                      const Text("Parcelas: "),
                      DropdownButton<int>(
                        value: _parcelas,
                        items: List.generate(12, (i) => i + 1).map((i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(),
                        onChanged: (v) => setState(() {
                           _parcelas = v!;
                           _atualizarParcelas();
                        }),
                      ),
                    ],
                  ),
                )
             else const Expanded(child: SizedBox()),
           ],
         ),
         const SizedBox(height: 16),
         const Text("Cronograma de Pagamentos:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
         const SizedBox(height: 8),
         ..._pagamentos.asMap().entries.map((e) {
           final idx = e.key;
           final p = e.value;
           return ListTile(
             dense: true,
             leading: CircleAvatar(radius: 12, child: Text("${p['numero']}", style: const TextStyle(fontSize: 10))),
             title: Text(DateFormat('dd/MM/yyyy').format(p['data'])),
             trailing: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(p['valor'])),
                 Checkbox(value: p['pago'], onChanged: (v) => setState(() => _pagamentos[idx]['pago'] = v)),
               ],
             ),
           );
         }).toList(),
      ],
    );
  }

  Widget _buildListaComprasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("LISTA DE COMPRAS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
            TextButton.icon(onPressed: _addItemCompra, icon: const Icon(Icons.add), label: const Text("ADICIONAR ITEM")),
          ],
        ),
        const SizedBox(height: 8),
        DataTable(
          columns: const [
            DataColumn(label: Text("Item")),
            DataColumn(label: Text("Categoria")),
            DataColumn(label: Text("Ações")),
          ],
          rows: _listaCompras.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            return DataRow(cells: [
              DataCell(Text(item['nome'])),
              DataCell(Text(item['categoria'])),
              DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => setState(() => _listaCompras.removeAt(idx)))),
            ]);
          }).toList(),
        ),
      ],
    );
  }

  void _addItemCompra() {
    final nomeController = TextEditingController();
    String categoria = 'Vestimenta';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Item de Compra"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome do Item")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: categoria,
              items: ['Vestimenta', 'Alimentar', 'Espiritual'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => categoria = v!,
              decoration: const InputDecoration(labelText: "Categoria"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(onPressed: () {
            setState(() => _listaCompras.add({'nome': nomeController.text, 'categoria': categoria}));
            Navigator.pop(context);
          }, child: const Text("ADICIONAR")),
        ],
      ),
    );
  }

  Widget _buildComidasRoncoSection() {
    return _buildItemsComida("COMIDAS DO RONCÓ / AJEUM", _comidasRonco);
  }

  Widget _buildComidasCongaSection() {
    return _buildItemsComida("OFERENDAS NO CONGÁ", _comidasConga);
  }

  Widget _buildItemsComida(String title, List<Map<String, dynamic>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
            TextButton.icon(onPressed: () => _addItemComida(list), icon: const Icon(Icons.add), label: const Text("ADICIONAR")),
          ],
        ),
        const SizedBox(height: 8),
        ...list.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          return Card(
            child: ListTile(
              title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['preparo'], maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => list.removeAt(idx))),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _addItemComida(List<Map<String, dynamic>> list) {
    final nomeController = TextEditingController();
    final preparoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova Comida/Oferenda"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome da Comida")),
            const SizedBox(height: 12),
            TextField(controller: preparoController, decoration: const InputDecoration(labelText: "Modo de Preparo"), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(onPressed: () {
             setState(() => list.add({'nome': nomeController.text, 'preparo': preparoController.text}));
             Navigator.pop(context);
          }, child: const Text("ADICIONAR")),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    if (_selectedMediumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um médium")));
      return;
    }

    final dataMap = {
      'mediumId': _selectedMediumId,
      'mediumNome': _selectedMediumNome,
      'tipoObrigacao': _tipoPerfil,
      'orixa': _selectedOrixa,
      'data': Timestamp.fromDate(_data),
      'valor': double.tryParse(_valorController.text) ?? 0,
      'metodoPagamento': _metodoPagamento,
      'parcelas': _parcelas,
      'pagamentos_detalhe': _pagamentos.map((p) => {
        ...p,
        'data': Timestamp.fromDate(p['data']),
      }).toList(),
      'listaCompras': _listaCompras,
      'comidasRonco': _comidasRonco,
      'comidasConga': _comidasConga,
      'participantesBanhoId': _participantesBanhoId,
      'custoErvas': double.tryParse(_custoErvaController.text) ?? 0,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    if (widget.doc == null) {
      await FirebaseFirestore.instance.collection('obrigacoes').add(dataMap);
    } else {
      await widget.doc!.reference.update(dataMap);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Obrigação salva!"), backgroundColor: Colors.green));
    }
  }
}

class _ListaFestas extends StatelessWidget {
  const _ListaFestas();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("FESTAS: Funcionalidade em desenvolvimento. Use o calendário para agendar festas."));
  }
}
