import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'child_pairing_screen.dart';
import 'plan_screen.dart';
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

  // true enquanto os dados exibidos vierem só do cache local (SharedPreferences),
  // e não da resposta do servidor.
  bool usandoCache = false;

  String nome = '';
  String email = '';
  String tipo = 'usuario';
  String responsavelNome = '';

  Map<String, dynamic>? assinatura;

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

  String _capitalizar(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Lê TODO o cache salvo localmente
    final nomeCache = prefs.getString('gn_nome') ?? '';
    final emailCache = prefs.getString('gn_email') ?? '';
    final tipoCache = prefs.getString('gn_tipo') ?? 'usuario';
    final responsavelCache = prefs.getString('gn_responsavel_nome') ?? '';

    // Recupera dados salvos do plano em cache (se houver)
    final planoNomeCache = prefs.getString('gn_plano_nome');
    Map<String, dynamic>? assinaturaCache;
    if (planoNomeCache != null) {
      assinaturaCache = {'plano': planoNomeCache};
    }

    final temCache = nomeCache.isNotEmpty;

    // 2. Renderiza os dados do cache IMEDIATAMENTE (zero espera visual)
    if (mounted) {
      setState(() {
        nome = nomeCache;
        email = emailCache;
        tipo = tipoCache;
        responsavelNome = responsavelCache;
        assinatura = assinaturaCache;
        usandoCache = true;
        // Se já tem cache, não mostra tela/spinner de carregamento
        loading = !temCache;
        erro = null;
      });
    }

    try {
      final token = prefs.getString('gn_token') ?? '';

      // 3. Chamadas paralelas da API
      final resultados = await Future.wait([
        http.get(
          Uri.parse('$apiBase/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        http.get(
          Uri.parse('$apiBase/subscription/current'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]).timeout(const Duration(seconds: 10)); // Reduzido para 10s para resposta mais rápida em falhas

      final respMe = resultados[0];
      final respSub = resultados[1];

      if (respMe.statusCode != 200) {
        debugPrint('Erro ao carregar /auth/me: status=${respMe.statusCode}');
        if (mounted) {
          setState(() {
            erro = respMe.statusCode == 401
                ? 'Sua sessão expirou. Entre novamente.'
                : 'Não foi possível atualizar seu perfil agora.';
            loading = false;
          });
        }
        return;
      }

      // Processa dados do perfil (/auth/me)
      final dataMe = jsonDecode(respMe.body) as Map<String, dynamic>;
      final novoNome = (dataMe['nome'] ?? nomeCache).toString();
      final novoEmail = (dataMe['email'] ?? emailCache).toString();
      final novoTipo = (dataMe['tipo'] ?? tipoCache).toString();
      final novoResp = (dataMe['responsavelNome'] ?? responsavelCache).toString();

      // Processa dados da assinatura (/subscription/current)
      Map<String, dynamic>? assinaturaCarregada = assinaturaCache;
      if (respSub.statusCode == 200) {
        final dataSub = jsonDecode(respSub.body) as Map<String, dynamic>;
        assinaturaCarregada = dataSub['assinatura'] as Map<String, dynamic>?;
      }

      // 4. Salva as informações ATUALIZADAS no cache local (SharedPreferences)
      await prefs.setString('gn_nome', novoNome);
      await prefs.setString('gn_email', novoEmail);
      await prefs.setString('gn_tipo', novoTipo);
      await prefs.setString('gn_responsavel_nome', novoResp);
      if (assinaturaCarregada != null && assinaturaCarregada['plano'] != null) {
        await prefs.setString('gn_plano_nome', assinaturaCarregada['plano'].toString());
      }

      // 5. Atualiza o estado da tela com os dados novos vindos do servidor
      if (mounted) {
        setState(() {
          nome = novoNome;
          email = novoEmail;
          tipo = novoTipo;
          responsavelNome = novoResp;
          assinatura = assinaturaCarregada;
          usandoCache = false;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Exceção ao carregar perfil: $e');
      if (mounted) {
        setState(() {
          // Se já tinha cache exibido, apenas remove o loading silenciosamente
          erro = temCache ? null : 'Sem conexão com o servidor.';
          loading = false;
        });
      }
    }
  }

  Future<void> _deslogar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _abrirPagina(Widget screen, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.navy,
          appBar: AppBar(
            backgroundColor: AppColors.navy,
            title: Text(title, style: const TextStyle(color: AppColors.branco)),
            iconTheme: const IconThemeData(color: AppColors.branco),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: screen,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.azulPastel),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (erro != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.perigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.perigo.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.perigo, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(erro!, style: const TextStyle(color: AppColors.perigo, fontSize: 12.5)),
                ),
                TextButton(
                  onPressed: _carregarPerfil,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Tentar de novo', style: TextStyle(color: AppColors.azulPastel, fontSize: 12.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        GlassCard(
          child: Row(
            children: [
              InitialsAvatar(initials: _iniciais, size: 54),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isNotEmpty ? nome : 'Usuário',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.branco),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isNotEmpty
                          ? email
                          : (usandoCache ? 'E-mail não disponível offline' : 'Sem e-mail'),
                      style: TextStyle(fontSize: 12.5, color: AppColors.brancoDim),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.navy3,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tipo == 'crianca' ? 'Perfil Infantil' : 'Responsável',
                        style: const TextStyle(fontSize: 11, color: AppColors.azulPastel, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPlanoCard(),
        const SizedBox(height: 20),
        LabelCaps('Configurações de Notificação'),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Notificações Push', style: TextStyle(color: AppColors.branco, fontSize: 13.5)),
                value: pushAlerts,
                activeThumbColor: AppColors.azulPastel,
                onChanged: (v) => setState(() => pushAlerts = v),
              ),
              Divider(color: AppColors.borda, height: 1),
              SwitchListTile(
                title: const Text('Resumo Semanal por E-mail', style: TextStyle(color: AppColors.branco, fontSize: 13.5)),
                value: weeklyEmail,
                activeThumbColor: AppColors.azulPastel,
                onChanged: (v) => setState(() => weeklyEmail = v),
              ),
              Divider(color: AppColors.borda, height: 1),
              SwitchListTile(
                title: const Text('Alertas Críticos via SMS', style: TextStyle(color: AppColors.branco, fontSize: 13.5)),
                value: smsCritical,
                activeThumbColor: AppColors.azulPastel,
                onChanged: (v) => setState(() => smsCritical = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LabelCaps('Aparência'),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: SwitchListTile(
            title: const Text('Modo escuro', style: TextStyle(color: AppColors.branco, fontSize: 13.5)),
            subtitle: Text('Ativado por padrão no GuardianNet', style: TextStyle(color: AppColors.brancoDim, fontSize: 11.5)),
            value: themeProv.isDark,
            activeThumbColor: AppColors.azulPastel,
            onChanged: (v) => themeProv.toggleTheme(v),
          ),
        ),
        const SizedBox(height: 20),
        LabelCaps('Ações Rápidas'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlineButtonCustom(
                text: 'Parear Dispositivo',
                icon: Icons.link,
                onPressed: () => _abrirPagina(const PairingScreen(), 'Pareamento'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlineButtonCustom(
                text: 'Sair da Conta',
                icon: Icons.logout,
                color: AppColors.perigo,
                onPressed: _deslogar,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanoCard() {
    if (assinatura == null) {
      return GlassCard(
        child: Row(
          children: [
            const Icon(Icons.star_border, color: AppColors.brancoDim),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usandoCache ? 'Plano não disponível offline' : 'Nenhum plano ativo',
                    style: const TextStyle(color: AppColors.branco),
                  ),
                  Text(
                    usandoCache
                        ? 'Toque em "Tentar de novo" acima para atualizar'
                        : 'Assine um plano no site para liberar os recursos',
                    style: TextStyle(color: AppColors.brancoDim, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final plano = _capitalizar((assinatura!['plano'] ?? '').toString());
    final status = (assinatura!['status'] ?? '').toString().toLowerCase();
    final statusLabel = {
      'ativa': 'Ativo',
      'trialing': 'Período de teste',
      'cancelada': 'Cancelado',
      'expirada': 'Expirado',
    }[status] ??
        _capitalizar(status);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _abrirPagina(const PlanScreen(), 'Plano de Assinatura'),
      child: GlassCard(
        child: Row(
          children: [
            const Icon(Icons.star, color: AppColors.atencao),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Plano $plano · $statusLabel', style: const TextStyle(color: AppColors.branco, fontSize: 14)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.brancoDim),
          ],
        ),
      ),
    );
  }
}