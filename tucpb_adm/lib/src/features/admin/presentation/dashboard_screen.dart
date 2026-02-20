import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/admin/data/dashboard_repository.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);
    final userData = userDataAsync.asData?.value;
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);
    final nome = userData?['nome'] ?? 'Membro';

    return Column(
      children: [
        if (!isAdmin && perfil != 'medium' && perfil != 'cambono')
          _AdminSetupBanner(ref: ref),
        const _DashboardHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GreetingsHeader(nome: nome),
                const SizedBox(height: 32),
                
                // Big Numbers
                const _StatsOverview(),
                const SizedBox(height: 32),
                
                // Próximos Pagamentos (Prominente)
                const _UpcomingPayments(),
                const SizedBox(height: 32),

                // Novo: Checklist para Próxima Gira / Estoque
                const _GiraChecklist(),
                const SizedBox(height: 32),
                
                // Novo: Agenda e Informações Importantes
                LayoutBuilder(builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: const _AgendaCard()),
                        const SizedBox(width: 24),
                        Expanded(child: const _ImportantInformation()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const _AgendaCard(),
                      const SizedBox(height: 24),
                      const _ImportantInformation(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GreetingsHeader extends StatelessWidget {
  final String nome;
  const _GreetingsHeader({required this.nome});

  String _getUmbandaGreeting() {
    final now = DateTime.now();
    final day = now.day;
    final month = now.month;

    // Datas Específicas
    if (month == 1 && day == 20) return "Okê Arô Oxóssi! Que a mira do grande caçador te traga foco e fartura neste dia de São Sebastião.";
    if (month == 3 && day == 21) return "Dia Nacional das Tradições de Matrizes Africanas. Respeito ao nosso Axé e às nossas raízes!";
    if (month == 4 && day == 23) return "Ogunhê! Patacorí Ogum! Que o senhor das demandas corte todo o mal com sua espada de São Jorge.";
    if (month == 5 && day == 13) return "Adorei as Almas! Salve a sabedoria dos Pretos Velhos e a vibração sagrada dos Ogãs.";
    if (month == 5 && day == 24) return "Optchá! Salve Santa Sarah Kali, o povo cigano e a doçura de Maria da Cuia.";
    if (month == 5 && day == 31) return "Obá Xirê! Que a força e o amor de Mamãe Obá tragam verdade e proteção.";
    if (month == 6 && [13, 24, 29].contains(day)) return "Kaô Kabecilé Xangô! Que o machado da justiça traga equilíbrio e vitórias em sua vida.";
    if (month == 7 && day == 26) return "Saluba Nanã! Que a sabedoria da vovó e a calma das águas paradas tragam paz ao seu coração.";
    if (month == 8 && day == 16) return "Atotô Obaluaê! Senhor da cura e da renovação, transforme as dores em saúde e axé.";
    if (month == 9 && day == 27) return "Onibeijada! Que a alegria e a doçura de Cosme, Damião e Doum tragam leveza à sua alma.";
    if (month == 10 && day == 12) return "Ora Yê Yê Ô Oxum! Que o ouro e as águas doces de Mamãe Oxum tragam prosperidade.";
    if (month == 11 && day == 2) return "Atotô Omolú! Respeito ao silêncio sagrado e à grande renovação da vida.";
    if (month == 11 && day == 15) return "Salve o Dia Nacional da Umbanda! Salve o Caboclo das Sete Encruzilhadas e Pai Antônio.";
    if (month == 12 && day == 4) return "Eparrey Iansã! Que os ventos de Santa Bárbara levem o que não serve e tragam coragem.";
    if (month == 12 && day == 8) return "Odoyá Iemanjá! Salve a rainha do mar e as bênçãos de Nossa Senhora da Conceição.";
    if (month == 12 && day == 13) return "Rerê Ewá! Salve o brilho e o mistério da senhora das cores e de Santa Luzia.";

    // Greetings por Mês (Base)
    switch (month) {
      case 1: return "Janeiro de Oxalá! Que a paz branca ilumine seus caminhos hoje e sempre.";
      case 2: return "Mês de purificação. Que as ondas de Iemanjá e a luz da Quaresma renovem suas energias.";
      case 3: return "Tempo de força. Que as espadas de Ogum cortem os obstáculos de sua jornada.";
      case 4: return "Páscoa e Renovação. Que o axé da ressurreição traga novos começos.";
      case 5: return "Mês das Almas. Que a paciência dos Pretos Velhos te ensine a vencer as demandas.";
      case 6: return "Justiça de Xangô. Que o senhor do fogo e do trovão equilibre sua caminhada.";
      case 7: return "Sabedoria de Nanã. Mês de olhar para dentro e buscar a cura no barro sagrado.";
      case 8: return "Mês de cura. Que Obaluaê limpe sua alma e proteja sua saúde.";
      case 9: return "Pureza da Beijada. Que o sorriso das crianças sagradas ilumine sua casa.";
      case 10: return "Amor de Oxum. Mês da doçura, da diplomacia e da riqueza espiritual.";
      case 11: return "Dia da Umbanda! Salve nossa religião, nosso porto seguro e nossa fé.";
      case 12: return "Encerramento de ciclo sob a proteção de Iemanjá e a força de Iansã. Muito Axé!";
      default: return "Que as forças da natureza e a luz dos Orixás tragam muito Axé para o seu dia!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bem-vindo, $nome! ✨",
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AdminTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getUmbandaGreeting(),
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AdminTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    // Retornando um header vazio ou apenas o espaço necessário
    return const SizedBox(height: 24);
  }
}


class _StatsOverview extends ConsumerWidget {
  const _StatsOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final userData = ref.watch(userDataProvider).asData?.value;
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);

    return statsAsync.when(
      data: (stats) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          final cards = [
            if (isAdmin)
              _StatCard(title: "Total de Médiuns", value: "${stats.totalMediums}", icon: FontAwesomeIcons.users, color: AdminTheme.primary, subtitle: "Membros ativos"),
            if (isAdmin)
              _StatCard(title: "Itens para Compra", value: "${stats.totalItensCompra}", icon: FontAwesomeIcons.cartShopping, color: Colors.orange, subtitle: "Falta no estoque"),
            
            _StatCard(title: "Próximas Giras", value: "${stats.proximasGiras}", icon: FontAwesomeIcons.calendarDays, color: const Color(0xFF5C6BC0), subtitle: "Próximas chamadas"),
            _StatCard(title: "Total de Atendimentos", value: "${stats.atendimentosPessoais}", icon: FontAwesomeIcons.handsPraying, color: const Color(0xFF66BB6A), subtitle: "Histórico total"),
            _StatCard(title: "Giras Presentes", value: "${stats.girasPresentes}", icon: FontAwesomeIcons.circleCheck, color: const Color(0xFF26A69A), subtitle: "Sua frequência"),
            _StatCard(title: "Giras Ausentes", value: "${stats.girasAusentes}", icon: FontAwesomeIcons.circleExclamation, color: const Color(0xFFEF5350), subtitle: "Faltas no período"),
          ];

          int columns = width > 1100 ? (isAdmin ? 3 : 4) : (width > 700 ? 2 : 1);
          if (width > 1200 && isAdmin) columns = 3; // 2 rows of 3
          
          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: width > 1100 ? 1.8 : (width > 700 ? 1.8 : 2.5),
            children: cards,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Erro: $err'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, color: color.withOpacity(0.05), size: 60),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.outfit(color: AdminTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: GoogleFonts.outfit(color: AdminTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingPayments extends ConsumerWidget {
  const _UpcomingPayments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Próximos Pagamentos & Histórico", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
              TextButton(onPressed: () {}, child: const Text("Ver Histórico Completo")),
            ],
          ),
          const SizedBox(height: 20),
          const Text("PENDENTES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _PaymentItem(titulo: "Mensalidade Fev/26", valor: "R\$ 100,00", data: "Vence em 25/02", status: "Pendente", statusColor: Colors.orange),
          const Divider(height: 32),
          const Text("HISTÓRICO (ÚLTIMO MÊS)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _PaymentItem(titulo: "Mensalidade Jan/26", valor: "R\$ 100,00", data: "Pago em 20/01", status: "Pago", statusColor: Colors.green),
          _PaymentItem(titulo: "Rifa Gira de Umbanda", valor: "R\$ 20,00", data: "Pago em 15/01", status: "Pago", statusColor: Colors.green),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String titulo, valor, data, status;
  final Color statusColor;
  const _PaymentItem({required this.titulo, required this.valor, required this.data, required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(status == "Pago" ? Icons.check : Icons.timer_outlined, color: statusColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(data, style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgendaCard extends ConsumerWidget {
  const _AgendaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider).asData?.value;
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);
    final userId = userData?['uid'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.calendarDay, color: AdminTheme.primary, size: 20),
              const SizedBox(width: 12),
              Text("Agenda", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          _buildAgendaSection("Próximas Giras", Icons.event, Colors.blue, 'gira'),
          _buildAgendaSection("Próximas Limpezas", Icons.cleaning_services, Colors.teal, 'limpeza', isCleaning: true, isAdmin: isAdmin, userId: userId),
          _buildAgendaSection("Próximas Entregas", Icons.inventory_2, Colors.orange, 'entrega'),
          _buildAgendaSection("Próximos Eventos", Icons.star, Colors.purple, 'evento'),
        ],
      ),
    );
  }

  Widget _buildAgendaSection(String title, IconData icon, Color color, String type, {bool isCleaning = false, bool isAdmin = false, String userId = ''}) {
    Query query = FirebaseFirestore.instance
        .collection('giras')
        .where('tipo', isEqualTo: type)
        .where('data', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('data')
        .limit(3);

    if (isCleaning && !isAdmin) {
      query = query.where('mediumId', isEqualTo: userId);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
            ],
          ),
        ),
        StreamBuilder(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 10, child: LinearProgressIndicator());
            if (!snapshot.hasData || (snapshot.data as dynamic).docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(left: 24, bottom: 16),
                child: Text("Nenhum evento agendado.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              );
            }
            return Column(
              children: (snapshot.data as dynamic).docs.map<Widget>((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['data'] as Timestamp).toDate();
                final formattedDate = DateFormat('dd/MM').format(date);
                return Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 8),
                  child: Row(
                    children: [
                      Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['nome'] ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCleaning && isAdmin && data['mediumNome'] != null)
                        Text(data['mediumNome'], style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ImportantInformation extends ConsumerWidget {
  const _ImportantInformation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(FontAwesomeIcons.circleInfo, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Text("Informações Importantes", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                ],
              ),
              // Only admins see the button to create reminders (usually in a separate management screen, but adding quick access)
              // This UI will be refined in the specific management screen implementation
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('lembretes').where('ativo', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || (snapshot.data as dynamic).docs.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("Ninguém disparou lembretes hoje.", style: TextStyle(color: Colors.grey)),
                ));
              }
              final docs = (snapshot.data as dynamic).docs;
              return Column(
                children: docs.map((d) => _ReminderItem(data: d.data() as Map<String, dynamic>)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReminderItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign, color: Colors.orange, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['titulo'] ?? 'Aviso', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                const SizedBox(height: 4),
                Text(data['mensagem'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Banner exibido quando o usuário logado ainda não é Admin
class _AdminSetupBanner extends StatefulWidget {
  final WidgetRef ref;
  const _AdminSetupBanner({required this.ref});

  @override
  State<_AdminSetupBanner> createState() => _AdminSetupBannerState();
}

class _AdminSetupBannerState extends State<_AdminSetupBanner> {
  bool _loading = false;

  Future<void> _tornarAdmin() async {
    setState(() => _loading = true);
    try {
      await setCurrentUserAsAdmin();
      widget.ref.invalidate(userDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Perfil atualizado para Admin!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.orange[50],
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Seu perfil não está configurado como Admin. Clique para corrigir.",
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _loading ? null : _tornarAdmin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Tornar Admin"),
          ),
        ],
      ),
    );
  }
}

class _GiraChecklist extends ConsumerWidget {
  const _GiraChecklist();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider).asData?.value;
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);
    final userId = userData?['docId'] ?? userData?['uid'] ?? '';

    if (isAdmin) {
      return _buildAdminChecklist(context);
    } else {
      return _buildMediumChecklist(context, userId);
    }
  }

  Widget _buildAdminChecklist(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_checkout, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Text("Checklist de Compras do Estoque", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('checklist_manual').where('comprado', isEqualTo: false).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("Nenhum item pendente no estoque.", style: TextStyle(color: Colors.grey));
              }
              final docs = snapshot.data!.docs;
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return CheckboxListTile(
                    title: Text(data['item'] ?? '', style: const TextStyle(fontSize: 14)),
                    subtitle: Text("Qtd: ${data['quantidade'] ?? ''}", style: const TextStyle(fontSize: 12)),
                    value: false,
                    onChanged: (v) {
                       doc.reference.update({'comprado': true, 'dataCompra': FieldValue.serverTimestamp()});
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediumChecklist(BuildContext context, String userId) {
    // 1. Achar a próxima gira
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('giras')
          .where('ativo', isEqualTo: true)
          .where('data', isGreaterThanOrEqualTo: DateTime.now())
          .orderBy('data')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
           return const SizedBox.shrink();
        }
        final docGira = snapshot.data!.docs.first;
        final dataGira = docGira.data() as Map<String, dynamic>;
        final nomeGira = dataGira['nome'] ?? '';
        final detectada = _detectarLinha(nomeGira);

        if (detectada.isEmpty) return const SizedBox.shrink();

        // 2. Buscar anotações do médium para essa linha
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('anotacoes')
              .doc(detectada)
              .snapshots(),
          builder: (context, snapNote) {
            if (!snapNote.hasData || !snapNote.data!.exists) return const SizedBox.shrink();
            final dataNote = snapNote.data!.data() as Map<String, dynamic>;
            final checklist = List<Map<String, dynamic>>.from(dataNote['checklist'] ?? []);
            
            if (checklist.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.list_alt, color: AdminTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text("Minha Lista: $detectada", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Providenciar para a próxima gira: ${DateFormat('dd/MM').format((dataGira['data'] as Timestamp).toDate())}", 
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ...checklist.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return CheckboxListTile(
                      title: Text(item['item'], style: const TextStyle(fontSize: 14)),
                      value: item['checked'] ?? false,
                      onChanged: (v) {
                        checklist[idx]['checked'] = v;
                        FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(userId)
                          .collection('anotacoes')
                          .doc(detectada)
                          .update({'checklist': checklist});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _detectarLinha(String nome) {
    final n = nome.toLowerCase();
    final linhas = [
      'Preto Velho', 'Caboclo', 'Erê (Criança)', 'Exu', 'Pombagira',
      'Baiano', 'Marinheiro', 'Boiadeiro', 'Cicano', 'Malandro (Zé Pelintra)',
      'Oriental', 'Cura', 'Ogum', 'Oxóssi', 'Xangô', 'Iansã', 'Oxum', 
      'Iemanjá', 'Nanã', 'Obaluaê', 'Omulu', 'Oxalá', 'Entrega'
    ];
    for (final linha in linhas) {
      if (n.contains(linha.toLowerCase())) return linha;
    }
    return '';
  }
}
