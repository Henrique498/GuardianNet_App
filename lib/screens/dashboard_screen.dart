import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_data.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';

const _grupos = ["Família", "Escola", "Amigos"];

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onVerTodosAlertas;
  const DashboardScreen({super.key, this.onVerTodosAlertas});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String nome = '';
  String grupoSelecionado = 'Família';

  @override
  void initState() {
    super.initState();
    _carregarNome();
  }

  Future<void> _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString('gn_nome') ?? '';
    if (mounted) setState(() => nome = n);
  }

  @override
  Widget build(BuildContext context) {
    final alerts = MockData.alerts;
    final contacts = MockData.contacts;
    final children = MockData.children;
    final critico = alerts.where((a) => a.level == AlertLevel.perigo).isNotEmpty
        ? alerts.firstWhere((a) => a.level == AlertLevel.perigo)
        : null;
    final contatosGrupo = contacts.where((c) => c.category == grupoSelecionado).toList();
    final primeiroNome = nome.isEmpty ? MockData.parent.name : nome.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabelCaps('Bem-vinda de volta'),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
            children: [
              const TextSpan(text: 'Olá, ', style: TextStyle(color: AppColors.branco)),
              TextSpan(text: primeiroNome, style: const TextStyle(color: AppColors.azulPastel)),
              const TextSpan(text: ' 👋', style: TextStyle(color: AppColors.branco)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Status geral
        GlassCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelCaps('Status geral'),
              const SizedBox(height: 8),
              const Text('Sua família está protegida',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.branco)),
              const SizedBox(height: 4),
              Text(
                '${children.length} dispositivos monitorados pela IA neste momento.',
                style: TextStyle(fontSize: 13, color: AppColors.brancoDim),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.navy3.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borda),
                    ),
                    child: Text('${c.name}, ${c.age} anos · ${c.status}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.branco)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        if (critico != null) ...[
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => showAlertDetailSheet(context, critico, onVerTodos: widget.onVerTodosAlertas),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.perigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.perigo.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.perigo),
                      const SizedBox(width: 6),
                      LabelCaps('Alerta crítico', color: AppColors.perigo),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(critico.category, style: const TextStyle(fontSize: 15, color: AppColors.branco)),
                  const SizedBox(height: 4),
                  Text(critico.description, style: TextStyle(fontSize: 13, color: AppColors.brancoDim)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Ver detalhes', style: TextStyle(fontSize: 13, color: AppColors.azulPastel)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14, color: AppColors.azulPastel),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.people_outline, size: 20, color: AppColors.azulPastel),
                    const SizedBox(height: 10),
                    Text('${contacts.length}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.branco)),
                    Text('Contatos confiáveis', style: TextStyle(fontSize: 11.5, color: AppColors.brancoDim)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_outlined, size: 20, color: AppColors.atencao),
                    const SizedBox(height: 10),
                    Text('${alerts.length}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.branco)),
                    Text('Alertas do mês', style: TextStyle(fontSize: 11.5, color: AppColors.brancoDim)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),
        LabelCaps('Contatos confiáveis'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _grupos
                .map((g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GradientChip(
                label: g,
                ativo: g == grupoSelecionado,
                onTap: () => setState(() => grupoSelecionado = g),
              ),
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        if (contatosGrupo.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhum contato neste grupo ainda.', style: TextStyle(color: AppColors.brancoDim, fontSize: 13)),
          )
        else
          ...contatosGrupo.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navy2.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borda.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                InitialsAvatar(initials: c.initials, size: 40, solid: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontSize: 13.5, color: AppColors.branco)),
                      Text(c.relation, style: TextStyle(fontSize: 11.5, color: AppColors.brancoDim)),
                    ],
                  ),
                ),
              ],
            ),
          )),

        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LabelCaps('Alertas recentes'),
            TextButton(
              onPressed: widget.onVerTodosAlertas,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text('Ver todos', style: TextStyle(fontSize: 12.5, color: AppColors.azulPastel)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...alerts.take(3).map((a) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => showAlertDetailSheet(context, a, onVerTodos: widget.onVerTodosAlertas),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${a.child} · ${a.app}',
                            style: const TextStyle(fontSize: 13.5, color: AppColors.branco)),
                      ),
                      RiskBadge(risk: a.level),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(a.description, style: TextStyle(fontSize: 12.5, color: AppColors.brancoDim)),
                  const SizedBox(height: 8),
                  Text(a.time, style: TextStyle(fontSize: 11, color: AppColors.brancoDim.withOpacity(0.7))),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }
}