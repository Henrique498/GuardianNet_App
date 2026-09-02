import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'alerts_screen.dart';
import 'contacts_screen.dart';
import 'child_pairing_screen.dart';
import 'plan_screen.dart';
import 'feedback_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../models/mock_data.dart';
import '../theme/app_theme.dart';
import 'child_home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _Secao { inicio, alertas, contatos, parear, plano, feedback, perfil, crianca }

class _NavItem {
  final _Secao secao;
  final String label;
  final IconData icon;
  const _NavItem(this.secao, this.label, this.icon);
}

const _navResponsavel = [
  _NavItem(_Secao.inicio, 'Início', Icons.home_rounded),
  _NavItem(_Secao.alertas, 'Central de Alertas', Icons.notifications_rounded),
  _NavItem(_Secao.contatos, 'Contatos Confiáveis', Icons.people_alt_rounded),
  _NavItem(_Secao.parear, 'Parear Dispositivo Infantil', Icons.link_rounded),
  _NavItem(_Secao.plano, 'Plano de Assinatura', Icons.credit_card_rounded),
  _NavItem(_Secao.perfil, 'Meu Perfil', Icons.person_rounded),
  _NavItem(_Secao.feedback, 'Feedback', Icons.favorite_rounded),
];

const _navCrianca = [
  _NavItem(_Secao.crianca, 'Início', Icons.verified_user_rounded),
  _NavItem(_Secao.perfil, 'Meu Perfil', Icons.person_rounded),
  _NavItem(_Secao.feedback, 'Feedback', Icons.favorite_rounded),
];

class _HomeShellState extends State<HomeShell> {
  _Secao secao = _Secao.inicio;
  String nome = '';
  String tipo = 'usuario';
  bool carregandoPrefs = true;

  @override
  void initState() {
    super.initState();
    _carregarPrefs();
  }

  Future<void> _carregarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final tipoSalvo = prefs.getString('gn_tipo') ?? 'usuario';
    setState(() {
      nome = prefs.getString('gn_nome') ?? '';
      tipo = tipoSalvo;
      secao = tipoSalvo == 'crianca' ? _Secao.crianca : _Secao.inicio;
      carregandoPrefs = false;
    });
  }

  String get _iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'CF';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }

  List<_NavItem> get _nav => tipo == 'crianca' ? _navCrianca : _navResponsavel;

  String get _titulo {
    switch (secao) {
      case _Secao.inicio:
        return '';
      case _Secao.alertas:
        return 'Central de Alertas';
      case _Secao.contatos:
        return 'Contatos Confiáveis';
      case _Secao.parear:
        return 'Parear Dispositivo';
      case _Secao.plano:
        return 'Plano de Assinatura';
      case _Secao.feedback:
        return 'Feedback';
      case _Secao.perfil:
        return 'Meu Perfil';
      case _Secao.crianca:
        return '';
    }
  }

  Widget get _pagina {
    switch (secao) {
      case _Secao.inicio:
        return DashboardScreen(onVerTodosAlertas: () => setState(() => secao = _Secao.alertas));
      case _Secao.alertas:
        return const AlertsScreen();
      case _Secao.contatos:
        return const ContactsScreen();
      case _Secao.parear:
        return const PairingScreen();
      case _Secao.plano:
        return const PlanScreen();
      case _Secao.feedback:
        return const FeedbackScreen();
      case _Secao.perfil:
        return const ProfileScreen();
      case _Secao.crianca:
        return const ChildHomeScreen();
    }
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

  void _abrirSecao(_Secao s) {
    Navigator.of(context).pop();
    setState(() => secao = s);
  }

  void _abrirNotificacoes() {
    final criticos = MockData.alerts.where((a) => a.level == AlertLevel.perigo).toList();
    if (criticos.isNotEmpty) {
      showAlertDetailSheet(
        context,
        criticos.first,
        onVerTodos: () => setState(() => secao = _Secao.alertas),
      );
    } else {
      setState(() => secao = _Secao.alertas);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregandoPrefs) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(child: CircularProgressIndicator(color: AppColors.azulPastel)),
      );
    }

    if (secao == _Secao.crianca) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: ChildHomeScreen(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.navy,
      drawer: _MenuGaveta(nome: nome, iniciais: _iniciais, itens: _nav, ativo: secao, onSelect: _abrirSecao, onSair: _sair),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        toolbarHeight: 68,
        leadingWidth: 68,
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  InitialsAvatar(initials: _iniciais, size: 42, solid: true),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(color: AppColors.navy2, shape: BoxShape.circle),
                      child: const Icon(Icons.menu_rounded, size: 10, color: AppColors.brancoDim),
                    ),
                  ),
                ],
              ),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(width: 60, height: 34, glow: true),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                children: [
                  TextSpan(text: 'Guardian', style: TextStyle(color: AppColors.branco)),
                  TextSpan(text: 'Net', style: TextStyle(color: AppColors.azulPastel)),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.navy2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borda),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.branco),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: AlertsInbox.hasUnreadCritical,
                      builder: (context, hasUnread, _) {
                        if (!hasUnread) return const SizedBox.shrink();
                        return Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(color: AppColors.perigo, shape: BoxShape.circle),
                        );
                      },
                    ),
                  ),
                ],
              ),
              onPressed: _abrirNotificacoes,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                children: [
                  if (_titulo.isNotEmpty) ...[
                    Text(_titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.branco)),
                    const SizedBox(height: 16),
                  ],
                  _pagina,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.seguro),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Monitoramento transparente e consentido pela criança, conforme a '
                            'Lei 15.211/2025 — Proteção Digital da Criança e do Adolescente.',
                        style: TextStyle(color: AppColors.brancoDim, fontSize: 11.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGaveta extends StatelessWidget {
  final String nome;
  final String iniciais;
  final List<_NavItem> itens;
  final _Secao ativo;
  final void Function(_Secao) onSelect;
  final VoidCallback onSair;

  const _MenuGaveta({
    required this.nome,
    required this.iniciais,
    required this.itens,
    required this.ativo,
    required this.onSelect,
    required this.onSair,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navy2,
      width: MediaQuery.of(context).size.width * 0.84,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  const AppLogo(width: 60, height: 34, glow: true),
                  const SizedBox(width: 10),
                  InitialsAvatar(initials: iniciais, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nome.isEmpty ? 'Usuário' : nome,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.branco),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.navy3, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final item in itens)
                    _ItemMenu(
                      icon: item.icon,
                      label: item.label,
                      ativo: item.secao == ativo,
                      onTap: () => onSelect(item.secao),
                    ),
                  const SizedBox(height: 8),
                  _ItemMenu(
                    icon: Icons.logout_rounded,
                    label: 'Sair',
                    ativo: false,
                    corDestaque: AppColors.perigo,
                    onTap: onSair,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ativo;
  final Color? corDestaque;
  final VoidCallback onTap;

  const _ItemMenu({
    required this.icon,
    required this.label,
    required this.ativo,
    required this.onTap,
    this.corDestaque,
  });

  @override
  Widget build(BuildContext context) {
    final cor = corDestaque ?? (ativo ? AppColors.azulPastel : AppColors.branco.withOpacity(0.85));
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ativo ? AppColors.navy3 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: cor),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 13.5, color: cor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}