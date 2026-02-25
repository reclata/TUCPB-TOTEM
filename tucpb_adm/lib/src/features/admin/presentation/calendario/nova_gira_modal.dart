import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/gira_model.dart';
import 'package:tucpb_adm/src/features/admin/data/giras_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class NovaGiraModal extends ConsumerStatefulWidget {
  final GiraModel? giraParaEditar;
  final DateTime? dataPreSelecionada;

  const NovaGiraModal({super.key, this.giraParaEditar, this.dataPreSelecionada});

  @override
  ConsumerState<NovaGiraModal> createState() => _NovaGiraModalState();
}

class _NovaGiraModalState extends ConsumerState<NovaGiraModal> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _horaInicioController = TextEditingController(text: '19:00');
  final _horaFimController = TextEditingController(text: '22:00');
  final _horarioKioskController = TextEditingController(text: '18:00');
  DateTime _dataSelecionada = DateTime.now();
  String _tipo = 'gira';
  String? _mediumId;
  String? _mediumNome;
  bool _ativo = true;
  bool _visivelAssistencia = true;
  bool _salvando = false;

  static const _tipos = ['gira', 'limpeza', 'entrega', 'festa', 'evento'];
  static const _tiposLabel = {'gira': 'Giras', 'limpeza': 'Limpeza', 'entrega': 'Entrega', 'festa': 'Festas', 'evento': 'Evento'};
  static const _tiposCores = {
    'gira': Color(0xFF1565C0),
    'limpeza': Color(0xFF00838F),
    'entrega': Color(0xFFFF9800),
    'festa': Color(0xFFAD1457),
    'evento': Color(0xFF2E7D32),
  };

  bool get _editando => widget.giraParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final g = widget.giraParaEditar!;
      _nomeController.text = g.nome;
      _descricaoController.text = g.descricao ?? '';
      _horaInicioController.text = g.horarioInicio;
      _horaFimController.text = g.horarioFim;
      _horarioKioskController.text = g.horarioKiosk;
      _dataSelecionada = g.data;
      _tipo = g.tipo;
      _mediumId = g.mediumId;
      _mediumNome = g.mediumNome;
      _ativo = g.ativo;
      _visivelAssistencia = g.visivelAssistencia;
    } else if (widget.dataPreSelecionada != null) {
      _dataSelecionada = widget.dataPreSelecionada!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da gira é obrigatório.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final repo = ref.read(girasRepositoryProvider);
      if (_editando) {
        await repo.atualizarGira(widget.giraParaEditar!.id, {
          'nome': _nomeController.text.trim(),
          'descricao': _descricaoController.text.trim(),
          'data': _dataSelecionada,
          'horarioInicio': _horaInicioController.text,
          'horarioFim': _horaFimController.text,
          'tipo': _tipo,
          'ativo': _ativo,
          'cor': GiraModel.defaultCor(_tipo),
          'mediumId': _tipo == 'limpeza' ? _mediumId : null,
          'mediumNome': _tipo == 'limpeza' ? _mediumNome : null,
          'visivelAssistencia': _visivelAssistencia,
          'horarioKiosk': _horarioKioskController.text,
        });
      } else {
        final novaGira = GiraModel(
          id: '',
          nome: _nomeController.text.trim(),
          data: _dataSelecionada,
          horarioInicio: _horaInicioController.text,
          horarioFim: _horaFimController.text,
          ativo: _ativo,
          descricao: _descricaoController.text.trim(),
          tipo: _tipo,
          mediumId: _tipo == 'limpeza' ? _mediumId : null,
          mediumNome: _tipo == 'limpeza' ? _mediumNome : null,
          visivelAssistencia: _visivelAssistencia,
          horarioKiosk: _horarioKioskController.text,
        );
        await repo.criarGira(novaGira);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editando ? 'Gira atualizada!' : 'Gira cadastrada e vinculada ao Totem! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editando ? 'Editar Gira' : 'Novo Evento / Gira',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Tipo
            const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tipos.map((t) {
                final selected = _tipo == t;
                final cor = _tiposCores[t]!;
                return ChoiceChip(
                  label: Text(_tiposLabel[t]!),
                  selected: selected,
                  selectedColor: cor,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                  onSelected: (_) => setState(() => _tipo = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Nome
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
                hintText: 'Ex: Gira de Preto Velho / Limpeza da Casa',
              ),
            ),
            const SizedBox(height: 16),

            // Seleção de Médium (apenas se for limpeza)
            if (_tipo == 'limpeza') ...[
              const Text('Médium escalado para limpeza', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                builder: (context, snapshot) {
                   if (!snapshot.hasData) return const LinearProgressIndicator();
                   final users = snapshot.data!.docs;
                   return Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                     child: DropdownButtonHideUnderline(
                       child: DropdownButton<String>(
                         value: _mediumId,
                         isExpanded: true,
                         hint: const Text("Selecione o médium"),
                         items: users.map((u) {
                           final data = u.data() as Map<String, dynamic>;
                           return DropdownMenuItem(
                             value: u.id,
                             child: Text(data['nome'] ?? 'Sem nome'),
                           );
                         }).toList(),
                         onChanged: (v) {
                           final userDoc = users.firstWhere((u) => u.id == v);
                           setState(() {
                             _mediumId = v;
                             _mediumNome = (userDoc.data() as Map<String, dynamic>)['nome'];
                           });
                         },
                       ),
                     ),
                   );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Data e Horários
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 200,
                  child: InkWell(
                    onTap: _selecionarData,
                    child: IgnorePointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Data',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _horaInicioController,
                    decoration: const InputDecoration(labelText: 'Início', border: OutlineInputBorder()),
                  ),
                ),
                  child: TextFormField(
                    controller: _horaFimController,
                    decoration: const InputDecoration(labelText: 'Fim', border: OutlineInputBorder()),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    controller: _horarioKioskController,
                    decoration: const InputDecoration(
                      labelText: 'Início Emissão Senhas (Kiosk)', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tablet_android),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descricaoController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Ativo
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo no sistema do Totem'),
              subtitle: const Text('Giras ativas aparecem no Totem para emissão de senhas', style: TextStyle(fontSize: 12)),
              value: _ativo,
              activeColor: AdminTheme.primary,
              onChanged: (v) => setState(() => _ativo = v),
            ),

            // Visível para Assistência
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visível para Assistência'),
              subtitle: const Text('Se marcado, o público externo poderá ver este evento', style: TextStyle(fontSize: 12)),
              value: _visivelAssistencia,
              activeColor: Colors.blue,
              onChanged: (v) => setState(() => _visivelAssistencia = v),
            ),
            const SizedBox(height: 16),

            // Aviso vinculação
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta gira será automaticamente vinculada ao sistema do Totem. Mediuns e senhas serão gerenciados lá.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botões
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, size: 16),
                  label: Text(_editando ? 'Salvar Alterações' : '+ Novo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
