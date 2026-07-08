import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'child_screen.dart';
import 'child_home_screen.dart';
import 'feedback_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  bool loading = true;
  bool isCrianca = false;

  @override
  void initState() {
    super.initState();
    _carregarTipoDeConta();
  }

  Future<void> _carregarTipoDeConta() async {
    final prefs = await SharedPreferences.getInstance();
    final tipo = prefs.getString('gn_tipo') ?? 'usuario';
    if (!mounted) return;
    setState(() {
      isCrianca = tipo == 'crianca';
      loading = false;
    });
  }

  // Contas de criança têm uma navegação enxuta e uma tela inicial própria
  // (ChildHomeScreen), diferente do dashboard do responsável.
  List<Widget> get _paginas => isCrianca
      ? const [
    ChildHomeScreen(),
    ChildScreen(),
    ProfileScreen(),
  ]
      : const [
    DashboardScreen(),
    AlertsScreen(),
    ProfileScreen(),
    ChildScreen(),
    FeedbackScreen(),
  ];

  List<NavigationDestination> get _destinos => isCrianca
      ? const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: "Início",
    ),
    NavigationDestination(
      icon: Icon(Icons.info_outline),
      selectedIcon: Icon(Icons.info),
      label: "Sobre",
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: "Perfil",
    ),
  ]
      : const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: "Início",
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: "Alertas",
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: "Perfil",
    ),
    NavigationDestination(
      icon: Icon(Icons.shield_outlined),
      selectedIcon: Icon(Icons.shield),
      label: "Criança",
    ),
    NavigationDestination(
      icon: Icon(Icons.feedback_outlined),
      selectedIcon: Icon(Icons.feedback),
      label: "Feedback",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final paginas = _paginas;
    // Segurança extra: evita index fora do range ao trocar de tipo de conta.
    if (index >= paginas.length) index = 0;

    return Scaffold(
      body: SafeArea(child: paginas[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: _destinos,
      ),
    );
  }
}