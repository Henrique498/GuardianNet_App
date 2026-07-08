import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../widgets/invite_child_sheet.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String apiBase = 'https://proteempreenda.onrender.com/api';

  bool pushAlerts = true;
  bool weeklyEmail = true;
  bool smsCritical = false;

  bool loading = true;
  String? erro;

  String nome = '';
  String email = '';
  String tipo = 'usuario'; // 'usuario' | 'crianca' | 'admin'
  String responsavelNome = '';

  Map<String, dynamic>? assinatura; // vem de /subscription/current

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  String get _iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }

  String _formatarData(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final dia = d.day.toString().padLeft(2, '0');
      final mes = d.month.toString().padLeft(2, '0');
      return '$dia/$mes/${d.year}';
    } catch (_) {
      return '';
    }
  }

  String _capitalizar(String v) => v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);

  Future<void> _irParaLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _carregarPerfil() async {
    setState(() {
      loading = true;
      erro = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('gn_token') ?? '';
      final tipoSalvo = prefs.getString('gn_tipo') ?? 'usuario';

      if (token.isEmpty) {
        await _irParaLogin();
        return;
      }

      // Conta de criança: usamos o que foi salvo no momento do pareamento.
      if (tipoSalvo == 'crianca') {
        setState(() {
          tipo = 'crianca';
          nome = prefs.getString('gn_nome') ?? 'Você';
          responsavelNome = prefs.getString('gn_responsavel_nome') ?? '';
          loading = false;
        });
        return;
      }

      final meResp = await http.get(
        Uri.parse('$apiBase/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (meResp.statusCode == 401) {
        await _irParaLogin();
        return;
      }

      final meData = jsonDecode(meResp.body) as Map<String, dynamic>;
      if (meResp.statusCode != 200) {
        setState(() {
          erro = meData['error']?.toString() ?? 'Não foi possível carregar seu perfil.';
          loading = false;
        });
        return;
      }

      Map<String, dynamic>? assinaturaData;
      try {
        final subResp = await http.get(
          Uri.parse('$apiBase/subscription/current'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (subResp.statusCode == 200) {
          final subJson = jsonDecode(subResp.body) as Map<String, dynamic>;
          assinaturaData = subJson['assinatura'] as Map<String, dynamic>?;
        }
      } catch (_) {
        // Se a assinatura falhar, o perfil ainda é exibido.
      }

      if (!mounted) return;
      setState(() {
        tipo = (meData['tipo'] ?? 'usuario').toString();
        nome = (meData['nome'] ?? '').toString();
        email = (meData['email'] ?? '').toString();
        assinatura = assinaturaData;
        loading = false;
      });

      await prefs.setString('gn_nome', nome);
    } catch (_) {
      setState(() {
        erro = 'Sem conexão com o servidor. Puxe para tentar novamente.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (erro != null) {
      return RefreshIndicator(
        onRefresh: _carregarPerfil,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(onPressed: _carregarPerfil, child: const Text('Tentar de novo')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarPerfil,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          const Text("Meu Perfil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  child: Text(_iniciais, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome.isEmpty ? 'Usuário' : nome,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (tipo == 'crianca')
                        Text(
                          responsavelNome.isEmpty
                              ? 'Conta vinculada a um responsável'
                              : 'Conectado(a) à conta de $responsavelNome',
                          style: const TextStyle(fontSize: 13),
                        )
                      else if (email.isNotEmpty)
                        Text(email),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (tipo != 'crianca') _buildAssinaturaCard(theme),

          const SizedBox(height: 20),
          _SectionTitle("NOTIFICAÇÕES"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text("Alertas no app"),
                  subtitle: const Text("Notificações push em tempo real"),
                  value: pushAlerts,
                  onChanged: (v) => setState(() => pushAlerts = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.public),
                  title: const Text("E-mail semanal"),
                  subtitle: const Text("Relatório de atividades"),
                  value: weeklyEmail,
                  onChanged: (v) => setState(() => weeklyEmail = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.sms_outlined),
                  title: const Text("SMS — alertas críticos"),
                  subtitle: const Text("Apenas nível Perigo"),
                  value: smsCritical,
                  onChanged: (v) => setState(() => smsCritical = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle("APARÊNCIA"),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text("Tema escuro"),
              subtitle: Text(themeProvider.isDark ? "Ativado" : "Desativado"),
              value: themeProvider.isDark,
              onChanged: (v) => themeProvider.toggleTheme(v),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle("CONTA"),
          Card(
            child: Column(
              children: [
                if (tipo != 'crianca') ...[
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text("Gerenciar Assinatura"),
                    subtitle: Text(assinatura == null ? "Nenhum plano ativo" : "Ver detalhes e faturamento"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: const Text("Convidar criança"),
                    subtitle: const Text("Gerar código de acesso"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showInviteChildSheet(context),
                  ),
                ] else
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text("Conta vinculada"),
                    subtitle: Text(responsavelNome.isEmpty ? "—" : responsavelNome),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle("LEGAL E CONFORMIDADE"),
          Card(
            child: ListTile(
              leading: const Icon(Icons.balance, color: Colors.amber),
              title: const Text("Lei 15.211/2025"),
              subtitle: const Text("Marco Legal IA — conformidade"),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text("Conforme", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              onPressed: _irParaLogin,
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Sair da Conta")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssinaturaCard(ThemeData theme) {
    if (assinatura == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.grey),
          title: const Text("Nenhum plano ativo"),
          subtitle: const Text("Assine um plano no site para liberar os recursos"),
        ),
      );
    }

    final plano = _capitalizar((assinatura!['plano'] ?? '').toString());
    final periodo = (assinatura!['periodo'] ?? '').toString();
    final status = (assinatura!['status'] ?? '').toString().toLowerCase();
    final proximaCobranca = _formatarData(assinatura!['nextBillingAt'] as String?);
    final trialFim = _formatarData(assinatura!['trialEndsAt'] as String?);

    final statusLabel = {
      'ativa': 'Ativo',
      'trialing': 'Período de teste',
      'cancelada': 'Cancelado',
      'expirada': 'Expirado',
    }[status] ?? _capitalizar(status);

    final statusColor = status == 'ativa' || status == 'trialing' ? Colors.amber : Colors.grey;

    String subtitulo;
    if (status == 'trialing' && trialFim.isNotEmpty) {
      subtitulo = 'Teste grátis até $trialFim';
    } else if (proximaCobranca.isNotEmpty) {
      subtitulo = 'Renova em $proximaCobranca · ${_capitalizar(periodo)}';
    } else {
      subtitulo = _capitalizar(periodo);
    }

    return Card(
      child: ListTile(
        leading: Icon(Icons.star, color: statusColor),
        title: Text("Plano $plano · $statusLabel"),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5, color: Colors.grey)),
    );
  }
}