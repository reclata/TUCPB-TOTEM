import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/activity_log_model.dart';
import 'package:tucpb_adm/src/features/admin/data/log_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class MovimentacaoScreen extends ConsumerWidget {
  const MovimentacaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsStreamProvider);

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Relatório de Movimentação", 
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Acompanhe quem incluiu, editou ou excluiu dados do sistema", 
                style: TextStyle(color: AdminTheme.textSecondary)),
            const SizedBox(height: 32),
            
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Erro ao carregar logs: $e")),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(child: Text("Nenhuma movimentação registrada."));
                  }
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _LogItem(log: log);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final ActivityLogModel log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _getActionColor(log.action);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(_getActionIcon(log.action), color: color, size: 20),
        ),
        title: Row(
          children: [
            Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  child: Text(log.module.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(log.description, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(LogActionType action) {
    return switch (action) {
      LogActionType.create => Colors.green,
      LogActionType.update => Colors.orange,
      LogActionType.delete => Colors.red,
      LogActionType.other => Colors.blueGrey,
    };
  }

  IconData _getActionIcon(LogActionType action) {
    return switch (action) {
      LogActionType.create => Icons.add_circle,
      LogActionType.update => Icons.edit,
      LogActionType.delete => Icons.delete,
      LogActionType.other => Icons.info,
    };
  }
}
