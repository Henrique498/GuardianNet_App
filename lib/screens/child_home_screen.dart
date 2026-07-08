import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tela inicial exibida SOMENTE para contas de criança (pareadas por código).
/// Diferente do dashboard do responsável: foco em tranquilizar a criança,
/// mostrar que ela está protegida e dar acesso rápido a "Estou bem" / SOS.
class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  static const Color verdePrincipal = Color(0xFF2ECC71);
  static const Color verdeEscuro = Color(0xFF1E9E58);
  static const Color verdeClaro = Color(0xFFEAF9EF);

  String nome = '';
  String responsavelNome = '';
  String horaAtiva = '';

  @override
  void initState() {
    super.initState();
    _definirHoraAtiva();
    _carregarDados();
  }

  void _definirHoraAtiva() {
    final agora = TimeOfDay.now();
    final h = agora.hourOfPeriod == 0 ? 12 : agora.hourOfPeriod;
    final m = agora.minute.toString().padLeft(2, '0');
    final periodo = agora.period == DayPeriod.am ? 'AM' : 'PM';
    horaAtiva = '$h:$m $periodo';
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      nome = prefs.getString('gn_nome') ?? '';
      responsavelNome = prefs.getString('gn_responsavel_nome') ?? '';
    });
  }

  void _avisarResponsavel() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: verdePrincipal, size: 40),
        title: const Text('Tudo certo!'),
        content: Text(
          responsavelNome.isEmpty
              ? 'Vamos avisar seu responsável que está tudo bem com você.'
              : 'Vamos avisar $responsavelNome que está tudo bem com você.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: verdePrincipal),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Responsável avisado! 💚')),
              );
            },
            child: const Text('Enviar aviso'),
          ),
        ],
      ),
    );
  }

  void _acionarSOS() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.sos_rounded, color: Colors.redAccent, size: 40),
        title: const Text('Pedir ajuda agora?'),
        content: Text(
          responsavelNome.isEmpty
              ? 'Isso vai enviar um alerta de emergência para seus responsáveis imediatamente.'
              : 'Isso vai enviar um alerta de emergência para $responsavelNome imediatamente.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Alerta de emergência enviado!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Enviar SOS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primeiroNome = nome.isEmpty ? '' : nome.split(' ').first;

    return Container(
      color: verdeClaro,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Cabeçalho verde ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [verdeEscuro, verdePrincipal],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'Protegido',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Olá,', style: TextStyle(color: Colors.white70, fontSize: 15)),
                Text(
                  '${primeiroNome.isEmpty ? "Amigo(a)" : primeiroNome}! 😊',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // ── Card de status ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(color: verdeClaro, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.verified_user, color: verdePrincipal, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sua proteção está ativa! 💪',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Você está seguro. Tudo monitorado.',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ativo desde as $horaAtiva',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Estou bem! / SOS ───────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _AcaoCard(
                          icon: Icons.check_circle,
                          iconColor: verdePrincipal,
                          iconBg: verdeClaro,
                          titulo: 'Estou bem!',
                          subtitulo: 'Avisar responsável',
                          onTap: _avisarResponsavel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AcaoCard(
                          icon: Icons.sos_rounded,
                          iconColor: Colors.redAccent,
                          iconBg: const Color(0xFFFFEAEC),
                          titulo: 'SOS',
                          subtitulo: 'Emergência',
                          tituloColor: Colors.redAccent,
                          onTap: _acionarSOS,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Localização ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: verdeClaro, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on_outlined, color: verdePrincipal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Localização compartilhada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('Em breve nesta versão', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: verdePrincipal, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Minha família ──────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MINHA FAMÍLIA',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (responsavelNome.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: const Text('Nenhum responsável vinculado ainda.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    _FamiliaCard(nome: responsavelNome),

                  const SizedBox(height: 20),

                  // ── Dica do dia ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dica do dia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                'Nunca compartilhe seu código com pessoas que você não conhece!',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcaoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String titulo;
  final String subtitulo;
  final Color? tituloColor;
  final VoidCallback onTap;

  const _AcaoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.tituloColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: tituloColor ?? Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(subtitulo, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FamiliaCard extends StatelessWidget {
  final String nome;
  const _FamiliaCard({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEAF9EF),
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const Text('Responsável', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFF2ECC71)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ligação em desenvolvimento.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF3B82F6)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mensagens em desenvolvimento.')),
              );
            },
          ),
        ],
      ),
    );
  }
}