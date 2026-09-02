import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mock_data.dart';
import '../theme/app_theme.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const String apiBase = 'https://proteempreenda.onrender.com/api';
  static const String siteUrl = 'https://proteempreenda.vercel.app/planos.html';

  bool loading = true;
  String? erro;
  Map<String, dynamic>? assinatura;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      loading = true;
      erro = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('gn_token') ?? '';
      final resp = await http.get(
        Uri.parse('$apiBase/subscription/current'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() => assinatura = data['assinatura'] as Map<String, dynamic>?);
      } else {
        setState(() => erro = 'Não foi possível carregar sua assinatura.');
      }
    } catch (_) {
      setState(() => erro = 'Sem conexão com o servidor.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _abrirPlanos() async {
    final uri = Uri.parse(siteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.borda)),
        title: const Text('Cancelar assinatura?', style: TextStyle(color: AppColors.branco)),
        content: Text(
          'Você continua com acesso até o fim do período já pago. Pode reativar quando quiser.',
          style: TextStyle(color: AppColors.brancoDim),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar assinatura', style: TextStyle(color: AppColors.perigo)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('gn_token') ?? '';
      final resp = await http.post(
        Uri.parse('$apiBase/subscription/cancel'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Assinatura cancelada. Você tem acesso até o fim do período pago.')));
        _carregar();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível cancelar agora.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sem conexão com o servidor.')));
    }
  }

  String _capitalizar(String v) => v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);

  String _formatarData(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.azulPastel)),
      );
    }

    if (erro != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(erro!, style: TextStyle(color: AppColors.brancoDim), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _carregar, child: const Text('Tentar de novo')),
          ],
        ),
      );
    }

    if (assinatura == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              children: [
                Icon(Icons.info_outline, color: AppColors.brancoDim, size: 28),
                const SizedBox(height: 10),
                const Text('Nenhum plano ativo', style: TextStyle(color: AppColors.branco, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Assine um plano no site para liberar todos os recursos.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.brancoDim, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Ver planos no site', icon: Icons.open_in_new, onPressed: _abrirPlanos),
        ],
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
    }[status] ??
        _capitalizar(status);

    String subtitulo;
    if (status == 'trialing' && trialFim.isNotEmpty) {
      subtitulo = 'Teste grátis até $trialFim';
    } else if (proximaCobranca.isNotEmpty) {
      subtitulo = 'Renova em $proximaCobranca';
    } else {
      subtitulo = _capitalizar(periodo);
    }

    final seats = MockData.plan.seats;
    final used = MockData.plan.used;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          glow: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.azulPastel),
                  const SizedBox(width: 6),
                  LabelCaps('Plano atual'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'GuardianNet $plano',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.azulPastel),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.navy3, borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.branco)),
              ),
              const SizedBox(height: 10),
              Text(subtitulo, style: TextStyle(fontSize: 13, color: AppColors.brancoDim)),

              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Perfis infantis', style: TextStyle(fontSize: 11.5, color: AppColors.brancoDim)),
                  Text('$used de $seats', style: TextStyle(fontSize: 11.5, color: AppColors.brancoDim)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: used / seats,
                  minHeight: 8,
                  backgroundColor: AppColors.navy3,
                  valueColor: const AlwaysStoppedAnimation(AppColors.verdePastel),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        LabelCaps('Incluso no plano'),
        const SizedBox(height: 10),
        ...MockData.plan.features.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.navy2.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borda.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_rounded, size: 16, color: AppColors.seguro),
              const SizedBox(width: 10),
              Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: AppColors.branco))),
            ],
          ),
        )),

        const SizedBox(height: 14),
        LabelCaps('Gerenciar assinatura'),
        const SizedBox(height: 10),
        GradientButton(label: 'Ver outros planos', icon: Icons.open_in_new, onPressed: _abrirPlanos),
        const SizedBox(height: 10),
        if (status == 'ativa' || status == 'trialing')
          OutlineButtonCustom(text: 'Cancelar assinatura', onPressed: _cancelar),
      ],
    );
  }
}