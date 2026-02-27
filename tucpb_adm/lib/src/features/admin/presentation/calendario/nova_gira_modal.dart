import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/gira_model.dart';
import 'package:tucpb_adm/src/features/admin/data/giras_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:tucpb_adm/src/shared/utils/spiritual_utils.dart';

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
  String _searchQuery = '';

  // Granular selection
  Map<String, bool> _mediumsSelected = {};
  Map<String, bool> _entitiesSelected = {};
  List<String> _selectedLinhas = [];
  String? _selectedTheme;
  bool _initialized = false;

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
      
      // Load current participants
      for (var mId in g.mediumsParticipantes) {
        _mediumsSelected[mId] = true;
      }
      for (var eId in g.entidadesParticipantes) {
        _entitiesSelected[eId] = true;
      }
    } else if (widget.dataPreSelecionada != null) {
      _dataSelecionada = widget.dataPreSelecionada!;
    }
  }

  void _onThemeChanged(String? theme, List<DocumentSnapshot> allMediumsDocs) {
    setState(() {
      _selectedTheme = theme;
      if (theme != null) {
        _nomeController.text = theme;
        _selectedLinhas = List.from(GIRA_THEME_MAPPING[theme] ?? []);
        
        // Sugerir flegues iniciais
        _mediumsSelected.clear();
        _entitiesSelected.clear();
        
        final allowedLinesNorm = _selectedLinhas.map((l) => normalizeSpiritualLine(l)).toList();
        for (var doc in allMediumsDocs) {
          final rawData = doc.data();
          if (rawData == null) continue;
          final data = Map<String, dynamic>.from(rawData as Map);
          if (data['ativo'] == false) continue;
          
          final rawEnt = data['entidades'];
          final entidades = rawEnt is List ? List<dynamic>.from(rawEnt) : [];
          final compatibleEntities = entidades.where((e) {
            if (e is! Map) return false;
            final entLinha = normalizeSpiritualLine(e['linha']?.toString() ?? '');
            final entTipo = normalizeSpiritualLine(e['tipo']?.toString() ?? '');
            return allowedLinesNorm.contains(entLinha) || allowedLinesNorm.contains(entTipo);
          }).toList();
          
          if (compatibleEntities.isNotEmpty) {
            _mediumsSelected[doc.id] = true;
            for (var e in compatibleEntities) {
              final eId = e['entidadeId'] ?? e['id'] ?? '';
              if (eId.isNotEmpty) _entitiesSelected[eId] = true;
            }
          }
        }
      }
    });
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
          'tema': _selectedTheme ?? _nomeController.text.trim(),
          'linha': normalizeSpiritualLine((_selectedTheme ?? _nomeController.text.trim()).replaceAll('Gira de ', '')),
          'ativo': _ativo,
          'cor': GiraModel.defaultCor(_tipo),
          'mediumId': _tipo == 'limpeza' ? _mediumId : null,
          'mediumNome': _tipo == 'limpeza' ? _mediumNome : null,
          'visivelAssistencia': _visivelAssistencia,
          'horarioKiosk': _horarioKioskController.text,
          'mediumsParticipantes': _mediumsSelected.entries.where((e) => e.value).map((e) => e.key).toList(),
          'entidadesParticipantes': _entitiesSelected.entries.where((e) => e.value).map((e) => e.key).toList(),
          'presencas': _mediumsSelected.entries.where((e) => e.value).fold<Map<String, bool>>({}, (map, e) {
             map[e.key] = true;
             return map;
          }),
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
          tema: _selectedTheme ?? _nomeController.text.trim(),
          linha: normalizeSpiritualLine((_selectedTheme ?? _nomeController.text.trim()).replaceAll('Gira de ', '')),
          mediumId: _tipo == 'limpeza' ? _mediumId : null,
          mediumNome: _tipo == 'limpeza' ? _mediumNome : null,
          visivelAssistencia: _visivelAssistencia,
          horarioKiosk: _horarioKioskController.text,
          mediumsParticipantes: _mediumsSelected.entries.where((e) => e.value).map((e) => e.key).toList(),
          entidadesParticipantes: _entitiesSelected.entries.where((e) => e.value).map((e) => e.key).toList(),
          presencas: _mediumsSelected.entries.where((e) => e.value).fold<Map<String, bool>>({}, (map, e) {
             map[e.key] = true;
             return map;
          }),
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

            // Seleção de Participantes
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                final allMediums = docs.where((d) {
                  final rawData = d.data();
                  if (rawData == null) return false;
                  final data = Map<String, dynamic>.from(rawData as Map);
                  if (data['ativo'] == false) return false;
                  
                  final perfil = (data['perfil'] ?? '').toString().toLowerCase();
                  final allowedProfiles = ['medium', 'médium', 'dirigente', 'admin', 'administrador'];
                  if (!allowedProfiles.contains(perfil)) return false;

                  final entidades = data['entidades'];
                  if (entidades is! List || entidades.isEmpty) return false;

                  return true;
                }).toList();

                if (!_initialized && _editando) {
                   // Tentar inferir o tema/linhas se estiver editando e vier sem nada
                   if (_selectedTheme == null && widget.giraParaEditar != null) {
                      for (var themeKey in GIRA_THEME_MAPPING.keys) {
                        if (widget.giraParaEditar!.nome.contains(themeKey)) {
                          _selectedTheme = themeKey;
                          _selectedLinhas = List.from(GIRA_THEME_MAPPING[themeKey] ?? []);
                          break;
                        }
                      }
                   }
                   _initialized = true;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tema da Gira (Sugestão de participantes)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: GIRA_THEME_MAPPING.keys.map((theme) {
                        final isSelected = _selectedTheme == theme;
                        return ChoiceChip(
                          label: Text(theme.replaceAll('Gira de ', '')),
                          selected: isSelected,
                          onSelected: (val) => _onThemeChanged(val ? theme : null, docs),
                          selectedColor: AdminTheme.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Médiuns e Guias Participantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Buscar médium...',
                              prefixIcon: Icon(Icons.search, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              final currentMediums = allMediums.where((d) => ((d.data() as Map<String, dynamic>)['nome'] ?? '').toString().toLowerCase().contains(_searchQuery)).toList();
                              
                              bool allSelected = currentMediums.isNotEmpty && currentMediums.every((d) => _mediumsSelected[d.id] == true);
                              bool nextState = !allSelected;

                              for (var mDoc in currentMediums) {
                                final mId = mDoc.id;
                                final mData = mDoc.data() as Map<String, dynamic>;
                                final entidades = List<Map<String, dynamic>>.from(mData['entidades'] ?? []);
                                final allowedLinesNorm = _selectedLinhas.map((l) => normalizeSpiritualLine(l)).toList();
                                final filteredEntidades = entidades.where((e) {
                                   if (allowedLinesNorm.isEmpty) return true;
                                   final entLinha = normalizeSpiritualLine(e['linha'] ?? '');
                                   final entTipo = normalizeSpiritualLine(e['tipo'] ?? '');
                                   return allowedLinesNorm.contains(entLinha) || allowedLinesNorm.contains(entTipo);
                                }).toList();

                                _mediumsSelected[mId] = nextState;
                                if (nextState) {
                                  for (var e in filteredEntidades) {
                                    final eId = e['entidadeId'] ?? e['id'] ?? '';
                                    if (eId.isNotEmpty) _entitiesSelected[eId] = true;
                                  }
                                } else {
                                  for (var e in entidades) {
                                    final eId = e['entidadeId'] ?? e['id'] ?? '';
                                    if (eId.isNotEmpty) _entitiesSelected[eId] = false;
                                  }
                                }
                              }
                            });
                          },
                          icon: const Icon(Icons.checklist, size: 20, color: AdminTheme.primary),
                          label: const Text('Selecionar Todos', style: TextStyle(color: AdminTheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                      child: ListView(
                        shrinkWrap: true,
                        children: allMediums.where((mDoc) {
                          final mData = mDoc.data() as Map<String, dynamic>;
                          final mNome = (mData['nome'] ?? 'Sem nome').toString().toLowerCase();
                          if (_searchQuery.isEmpty) return true;
                          if (mNome.contains(_searchQuery)) return true;
                          
                          final entidades = List<Map<String, dynamic>>.from(mData['entidades'] ?? []);
                          for (var e in entidades) {
                            final eNome = (e['entidadeNome'] ?? e['nome'] ?? '').toString().toLowerCase();
                            final eLinha = (e['linha'] ?? '').toString().toLowerCase();
                            final eTipo = (e['tipo'] ?? '').toString().toLowerCase();
                            if (eNome.contains(_searchQuery) || eLinha.contains(_searchQuery) || eTipo.contains(_searchQuery)) return true;
                          }
                          return false;
                        }).map((mDoc) {
                          final mData = mDoc.data() as Map<String, dynamic>;
                          final mId = mDoc.id;
                          final mNome = mData['nome'] ?? 'Sem nome';
                          final entidades = List<Map<String, dynamic>>.from(mData['entidades'] ?? []);
                          
                          final allowedLinesNorm = _selectedLinhas.map((l) => normalizeSpiritualLine(l)).toList();
                          final filteredEntidades = entidades.where((e) {
                             if (allowedLinesNorm.isEmpty) return true;
                             final entLinha = normalizeSpiritualLine(e['linha'] ?? '');
                             final entTipo = normalizeSpiritualLine(e['tipo'] ?? '');
                             return allowedLinesNorm.contains(entLinha) || allowedLinesNorm.contains(entTipo);
                          }).toList();

                          final isMediumSelected = _mediumsSelected[mId] ?? false;

                          return ExpansionTile(
                            leading: Checkbox(
                              value: isMediumSelected,
                              activeColor: AdminTheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  _mediumsSelected[mId] = val ?? false;
                                  if (val == true) {
                                    for (var e in filteredEntidades) {
                                      final eId = e['entidadeId'] ?? e['id'] ?? '';
                                      if (eId.isNotEmpty) _entitiesSelected[eId] = true;
                                    }
                                  } else {
                                    for (var e in entidades) {
                                      final eId = e['entidadeId'] ?? e['id'] ?? '';
                                      if (eId.isNotEmpty) _entitiesSelected[eId] = false;
                                    }
                                  }
                                });
                              },
                            ),
                            title: Text(mNome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text("${filteredEntidades.length} guia(s) compatíveis", style: const TextStyle(fontSize: 11)),
                            children: filteredEntidades.map((e) {
                              final eId = e['entidadeId'] ?? e['id'] ?? '';
                              final eNome = e['entidadeNome'] ?? e['nome'] ?? 'Sem nome';
                              return CheckboxListTile(
                                title: Text(eNome, style: const TextStyle(fontSize: 13)),
                                subtitle: Text("${e['linha'] ?? ''}${ (e['tipo'] ?? '').isNotEmpty && e['tipo'] != e['linha'] ? ' - ${e['tipo']}' : '' }", style: const TextStyle(fontSize: 11)),
                                value: _entitiesSelected[eId] ?? false,
                                activeColor: AdminTheme.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _entitiesSelected[eId] = val ?? false;
                                    if (val == true) _mediumsSelected[mId] = true;
                                  });
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
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
                SizedBox(
                  width: 140,
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
