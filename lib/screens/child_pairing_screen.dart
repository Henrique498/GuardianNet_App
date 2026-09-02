import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  static const String baseUrl = 'https://proteempreenda.onrender.com/api/pairing';

  bool loading = false;
  String? codigo;
  String? erro;
  Duration restante = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _gerarCodigo() async {
    setState(() {
      loading = true;
      erro = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('gn_token') ?? '';

      final resp = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 201 && data['ok'] == true) {
        final minutos = (data['expiraEmMinutos'] ?? 10) as int;
        setState(() {
          codigo = (data['codigo'] ?? '').toString();
          restante = Duration(minutes: minutos);
        });
        _iniciarContagem();
      } else {
        setState(() => erro = data['error']?.toString() ?? 'Não foi possível gerar o código.');
      }
    } catch (_) {
      setState(() => erro = 'Sem conexão. Tente novamente.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _iniciarContagem() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (restante.inSeconds <= 1) {
        t.cancel();
        setState(() => restante = Duration.zero);
        return;
      }
      setState(() => restante -= const Duration(seconds: 1));
    });
  }

  void _copiar() {
    if (codigo == null) return;
    Clipboard.setData(ClipboardData(text: codigo!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
  }

  String get _tempoFormatado {
    final m = restante.inMinutes.toString().padLeft(2, '0');
    final s = (restante.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _expirado => codigo != null && restante == Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          glow: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.navy3, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.smartphone_outlined, color: AppColors.azulPastel, size: 24),
              ),
              const SizedBox(height: 16),
              const Text('Conecte o celular da criança',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.branco)),
              const SizedBox(height: 8),
              Text(
                'Abra o GuardianNet no dispositivo infantil e digite o código abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.brancoDim, height: 1.5),
              ),
              if (erro != null) ...[
                const SizedBox(height: 16),
                Text(erro!, style: const TextStyle(color: AppColors.perigo, fontSize: 13), textAlign: TextAlign.center),
              ],
              if (codigo != null) ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: codigo!
                      .split('')
                      .map((d) => Container(
                    width: 44,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navy3,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borda),
                    ),
                    child: Text(
                      _expirado ? '–' : d,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.branco),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  _expirado ? 'Código expirado' : 'Expira em $_tempoFormatado',
                  style: TextStyle(fontSize: 12, color: AppColors.brancoDim),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlineButtonCustom(
                        text: 'Copiar',
                        icon: Icons.copy_rounded,
                        onPressed: _expirado ? null : _copiar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: 'Novo código',
                        icon: Icons.refresh_rounded,
                        loading: loading,
                        onPressed: loading ? null : _gerarCodigo,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Gerar código de 6 dígitos',
                  loading: loading,
                  onPressed: loading ? null : _gerarCodigo,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        ...[
          'Instale o GuardianNet no celular da criança.',
          'Toque em "Sou uma criança" e informe o código.',
          'Explique juntos como a proteção funciona e confirme o consentimento.',
        ].asMap().entries.map(
              (e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navy2.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borda.withOpacity(0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                  child: Text('${e.key + 1}',
                      style: const TextStyle(fontSize: 11, color: AppColors.azulPastel, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(e.value, style: TextStyle(fontSize: 13, color: AppColors.brancoDim, height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}