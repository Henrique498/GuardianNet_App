import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showInviteChildSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const InviteChildSheet(),
  );
}

class InviteChildSheet extends StatefulWidget {
  const InviteChildSheet({super.key});

  @override
  State<InviteChildSheet> createState() => _InviteChildSheetState();
}

class _InviteChildSheetState extends State<InviteChildSheet> {
  static const String baseUrl = 'https://proteempreenda.onrender.com/api/pairing';

  bool loading = true;
  String? codigo;
  String? erro;
  Duration restante = const Duration(minutes: 10);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _gerarCodigo();
  }

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
        setState(() => codigo = null);
        return;
      }
      setState(() => restante -= const Duration(seconds: 1));
    });
  }

  String get _tempoFormatado {
    final m = restante.inMinutes.toString().padLeft(2, '0');
    final s = (restante.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.family_restroom, color: theme.primaryColor, size: 36),
          const SizedBox(height: 12),
          const Text('Convidar criança', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          const Text(
            'Peça para ela abrir o app, tocar em\n"Sou uma criança" e digitar este código.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            )
          else if (erro != null) ...[
            Text(erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _gerarCodigo, child: const Text('Tentar de novo')),
          ] else if (codigo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.primaryColor.withOpacity(0.25)),
              ),
              child: Text(
                codigo!.split('').join('  '),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Expira em $_tempoFormatado', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ] else ...[
            const Text('Código expirado.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
              onPressed: _gerarCodigo,
              child: const Text('Gerar novo código'),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
          ),
        ],
      ),
    );
  }
}