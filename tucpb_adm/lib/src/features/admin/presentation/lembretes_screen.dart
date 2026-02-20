import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:intl/intl.dart';

class LembretesScreen extends ConsumerStatefulWidget {
  const LembretesScreen({super.key});

  @override
  ConsumerState<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends ConsumerState<LembretesScreen> {
  final _tituloController = TextEditingController();
  final _mensagemController = TextEditingController();
  bool _isLoading = false;

  Future<void> _enviarLembrete() async {
    if (_tituloController.text.isEmpty || _mensagemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('lembretes').add({
        'titulo': _tituloController.text.trim(),
        'mensagem': _mensagemController.text.trim(),
        'data': FieldValue.serverTimestamp(),
        'ativo': true,
        'criadoPor': 'Admin',
      });

      _tituloController.clear();
      _mensagemController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lembrete enviado com sucesso!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Central de Lembretes",
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "Dispare avisos importantes para todos os usuários do sistema.",
              style: GoogleFonts.outfit(fontSize: 16, color: AdminTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formulário de Criação
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("NOVO LEMBRETE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.primary)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _tituloController,
                          decoration: const InputDecoration(
                            labelText: "Título do Lembrete",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _mensagemController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: "Mensagem completa",
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.message),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _enviarLembrete,
                            icon: const Icon(Icons.send),
                            label: Text(_isLoading ? "ENVIANDO..." : "DISPARAR LEMBRETE"),
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
                ),
                const SizedBox(width: 32),
                // Lista de Lembretes Enviados
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("LEMBRETES RECENTES", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.primary)),
                        const SizedBox(height: 24),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('lembretes').orderBy('data', descending: true).limit(10).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum lembrete enviado ainda."));

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final doc = snapshot.data!.docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final timestamp = data['data'] as Timestamp?;
                                final dataFormatada = timestamp != null ? DateFormat('dd/MM HH:mm').format(timestamp.toDate()) : '--/--';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(data['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(data['mensagem'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(dataFormatada, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Switch(
                                        value: data['ativo'] ?? false,
                                        onChanged: (v) => doc.reference.update({'ativo': v}),
                                        activeColor: Colors.green,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
