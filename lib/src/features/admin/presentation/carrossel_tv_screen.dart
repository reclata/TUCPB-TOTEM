import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';
import '../data/admin_repository.dart';

final adminTvPanelsProvider = StreamProvider.autoDispose<List<TvPanel>>((ref) {
  return ref.read(adminRepositoryProvider).streamTvPanels('demo-terreiro');
});

class CarrosselTvScreen extends ConsumerStatefulWidget {
  const CarrosselTvScreen({super.key});

  @override
  ConsumerState<CarrosselTvScreen> createState() => _CarrosselTvScreenState();
}

class _CarrosselTvScreenState extends ConsumerState<CarrosselTvScreen> {
  String? _selectedPanelId;
  final _urlController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _defaultImages = [
    "assets/images/TUCPB 1.png",
    "assets/images/TUCPB 2.png",
    "assets/images/TUCPB 3.png",
    "assets/images/TUCPB 4.png",
    "assets/images/TUCPB 5.png",
    "assets/images/TUCPB 8.png",
    "assets/images/TUCPB 7.png",
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage(TvPanel panel) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Não foi possível ler o arquivo. Tente novamente."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child('carousel/$fileName');

      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/${file.extension ?? 'jpeg'}'),
      );

      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          setState(() {
            _uploadProgress = event.bytesTransferred / event.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final currentList = List<String>.from(panel.carouselImages ?? _defaultImages);
      currentList.add(downloadUrl);

      final updatedPanel = TvPanel(
        id: panel.id,
        terreiroId: panel.terreiroId,
        nomePainel: panel.nomePainel,
        status: panel.status,
        modo: panel.modo,
        entidadeId: panel.entidadeId,
        giraId: panel.giraId,
        ultimaAtualizacao: DateTime.now(),
        senhaAtual: panel.senhaAtual,
        carouselImages: currentList,
      );

      await ref.read(adminRepositoryProvider).updateTvPanel(updatedPanel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Imagem enviada e adicionada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar imagem: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _addUrlImage(TvPanel panel) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, insira uma URL válida (começando com http:// ou https://)"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final currentList = List<String>.from(panel.carouselImages ?? _defaultImages);
      currentList.add(url);

      final updatedPanel = TvPanel(
        id: panel.id,
        terreiroId: panel.terreiroId,
        nomePainel: panel.nomePainel,
        status: panel.status,
        modo: panel.modo,
        entidadeId: panel.entidadeId,
        giraId: panel.giraId,
        ultimaAtualizacao: DateTime.now(),
        senhaAtual: panel.senhaAtual,
        carouselImages: currentList,
      );

      await ref.read(adminRepositoryProvider).updateTvPanel(updatedPanel);
      _urlController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("URL da imagem adicionada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao adicionar URL: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(TvPanel panel, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover Imagem', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza que deseja remover esta imagem do carrossel da TV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentList = List<String>.from(panel.carouselImages ?? _defaultImages);
      final removedImage = currentList.removeAt(index);

      // Se for uma imagem do storage, tentar deletá-la para economizar espaço
      if (removedImage.contains('firebasestorage.googleapis.com')) {
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(removedImage);
          await storageRef.delete();
        } catch (e) {
          debugPrint('Aviso ao deletar imagem do storage: $e');
        }
      }

      final updatedPanel = TvPanel(
        id: panel.id,
        terreiroId: panel.terreiroId,
        nomePainel: panel.nomePainel,
        status: panel.status,
        modo: panel.modo,
        entidadeId: panel.entidadeId,
        giraId: panel.giraId,
        ultimaAtualizacao: DateTime.now(),
        senhaAtual: panel.senhaAtual,
        carouselImages: currentList,
      );

      await ref.read(adminRepositoryProvider).updateTvPanel(updatedPanel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Imagem removida com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao remover imagem: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreDefaults(TvPanel panel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restaurar Padrão', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Deseja restaurar as imagens originais do carrossel? Todas as imagens personalizadas inseridas neste painel serão removidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RESTAURAR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Tentar limpar imagens personalizadas do storage
      if (panel.carouselImages != null) {
        for (var img in panel.carouselImages!) {
          if (img.contains('firebasestorage.googleapis.com')) {
            try {
              final storageRef = FirebaseStorage.instance.refFromURL(img);
              await storageRef.delete();
            } catch (e) {
              debugPrint('Aviso ao deletar imagem durante restauração: $e');
            }
          }
        }
      }

      final updatedPanel = TvPanel(
        id: panel.id,
        terreiroId: panel.terreiroId,
        nomePainel: panel.nomePainel,
        status: panel.status,
        modo: panel.modo,
        entidadeId: panel.entidadeId,
        giraId: panel.giraId,
        ultimaAtualizacao: DateTime.now(),
        senhaAtual: panel.senhaAtual,
        carouselImages: null, // Volta ao padrão
      );

      await ref.read(adminRepositoryProvider).updateTvPanel(updatedPanel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Carrossel padrão restaurado!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao restaurar carrossel: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvPanelsAsync = ref.watch(adminTvPanelsProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: tvPanelsAsync.when(
        data: (panels) {
          if (panels.isEmpty) {
            return const Center(
              child: Text("Nenhum Painel de TV encontrado."),
            );
          }

          // Seleciona o primeiro painel por padrão se nenhum estiver selecionado
          if (_selectedPanelId == null || !panels.any((p) => p.id == _selectedPanelId)) {
            _selectedPanelId = panels.first.id;
          }

          final activePanel = panels.firstWhere((p) => p.id == _selectedPanelId);
          final images = activePanel.carouselImages ?? _defaultImages;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carrossel de Imagens da TV',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gerencie os slides exibidos na TV quando nenhuma senha está sendo chamada.',
                          style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Seletor de Painel
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.brown[200]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPanelId,
                          style: GoogleFonts.outfit(color: Colors.brown[900], fontWeight: FontWeight.bold, fontSize: 14),
                          items: panels.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text(p.nomePainel),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPanelId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Seção de Ações / Adicionar
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Adicionar Nova Imagem",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upload Button
                            Expanded(
                              flex: 2,
                              child: _isUploading
                                  ? Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.brown[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.brown[200]!),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              value: _uploadProgress > 0 ? _uploadProgress : null,
                                              strokeWidth: 2.5,
                                              color: Colors.brown,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _uploadProgress > 0
                                                ? "Enviando: ${(_uploadProgress * 100).toInt()}%"
                                                : "Preparando upload...",
                                            style: GoogleFonts.outfit(
                                                color: Colors.brown[800], fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.brown[800],
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 56),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => _uploadImage(activePanel),
                                      icon: const Icon(Icons.upload),
                                      label: Text(
                                        "FAZER UPLOAD DE IMAGEM",
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 24),
                            // URL Field
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _urlController,
                                      decoration: InputDecoration(
                                        hintText: "Ou cole a URL externa de uma imagem...",
                                        prefixIcon: const Icon(Icons.link),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                      ),
                                      onSubmitted: (_) => _addUrlImage(activePanel),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[800],
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(80, 56),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => _addUrlImage(activePanel),
                                    child: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Lista Grid de Imagens Atuais
                Row(
                  children: [
                    Text(
                      "Imagens no Carrossel (${images.length})",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    const Spacer(),
                    if (activePanel.carouselImages != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.brown[700]),
                        onPressed: () => _restoreDefaults(activePanel),
                        icon: const Icon(Icons.settings_backup_restore, size: 18),
                        label: Text(
                          "Restaurar Padrão",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final path = images[index];
                    final isCustom = path.startsWith('http');

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                      elevation: 1,
                      child: Stack(
                        children: [
                          // Imagem
                          Positioned.fill(
                            child: path.startsWith('http')
                                ? Image.network(
                                    path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                    ),
                                  )
                                : Image.asset(
                                    path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                    ),
                                  ),
                          ),
                          // Overlay de informações e remoção
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          // Badge de Custom / Default
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCustom ? Colors.amber[800]!.withOpacity(0.9) : Colors.brown.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isCustom ? "Custom" : "Padrão",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Botão Excluir
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.red.withOpacity(0.9),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                                onPressed: () => _removeImage(activePanel, index),
                                tooltip: "Remover Imagem",
                              ),
                            ),
                          ),
                          // Descrição da imagem / Posição
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              "Slide ${index + 1}",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.brown)),
        error: (e, s) => Center(child: Text("Erro ao carregar painéis de TV: $e")),
      ),
    );
  }
}
