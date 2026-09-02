import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  String nome = '';
  String responsavelNome = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      nome = prefs.getString('gn_nome') ?? '';
      responsavelNome = prefs.getString('gn_responsavel_nome') ?? 'Maria (Mãe)';
    });
  }

  Future<void> _sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _acionarSOS() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navy2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.borda)),
        icon: const Icon(Icons.sos_rounded, color: AppColors.perigo, size: 40),
        title: const Text('Pedir ajuda agora?', style: TextStyle(color: AppColors.branco)),
        content: Text(
          responsavelNome.isEmpty
              ? 'Isso vai enviar um alerta de emergência para seus responsáveis imediatamente.'
              : 'Isso vai enviar um alerta de emergência para $responsavelNome imediatamente.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.brancoDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.brancoDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.perigo),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Alerta de emergência enviado!'),
                  backgroundColor: AppColors.perigo,
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
    final primeiroNome = nome.isEmpty ? 'Lucas' : nome.split(' ').first;

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Topo: Modo criança / Oi, [Nome]! ──────────────
            Row(
              children: [
                // Container circular atualizado com BoxFit.cover
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.azulPastel.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azulPastel.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'lib/assests/images/logo.png',
                      fit: BoxFit.cover, // Preenche todo o círculo perfeitamente, removendo faixas/achatamento
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.navy2,
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.verdePastel,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modo criança',
                        style: TextStyle(color: AppColors.brancoDim, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          children: [
                            const TextSpan(text: 'Oi, ', style: TextStyle(color: AppColors.branco)),
                            TextSpan(text: '$primeiroNome!', style: const TextStyle(color: AppColors.verdePastel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navy2,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borda),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.brancoDim, size: 18),
                    onPressed: _sair,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Card Central: Proteção Ligada ────────────────
            GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF86EFAC), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verdePastel.withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.navy, size: 44),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Proteção ligada',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.branco),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'O GuardianNet está cuidando de você em Android · Dispositivo Ativo. '
                        'Nada é lido em segredo — ele só avisa seus responsáveis se encontrar algo que possa te machucar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.brancoDim, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Botão SOS: Preciso de ajuda agora ────────────
            InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: _acionarSOS,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.perigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.perigo.withOpacity(0.35)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.support_rounded, color: AppColors.perigo, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Preciso de ajuda agora',
                      style: TextStyle(
                        color: AppColors.perigo,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Seção: Quem posso chamar ─────────────────────
            const LabelCaps('QUEM POSSO CHAMAR'),
            const SizedBox(height: 12),

            _ContatoCard(
              initials: 'AF',
              nome: 'Ana Ferreira',
              relacao: 'Avó',
            ),
            const SizedBox(height: 10),
            _ContatoCard(
              initials: 'RF',
              nome: 'Rafael Ferreira',
              relacao: 'Pai',
            ),
            const SizedBox(height: 10),
            _ContatoCard(
              initials: 'MF',
              nome: responsavelNome.isEmpty ? 'Maria Ferreira' : responsavelNome,
              relacao: 'Mãe',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ContatoCard extends StatelessWidget {
  final String initials;
  final String nome;
  final String relacao;

  const _ContatoCard({
    required this.initials,
    required this.nome,
    required this.relacao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navy2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borda),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: initials, size: 42, solid: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.branco)),
                const SizedBox(height: 2),
                Text(relacao, style: const TextStyle(color: AppColors.brancoDim, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.verdePastel.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_outlined, color: AppColors.verdePastel, size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chamando $nome...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}