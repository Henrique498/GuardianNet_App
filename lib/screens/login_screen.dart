import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'home_shell.dart';
import 'child_pairing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String baseUrl = 'https://proteempreenda.onrender.com/api/auth';
  static const String siteUrl = 'https://proteempreenda.vercel.app/planos.html';

  bool obscure = true;
  bool loading = false;
  String? errorMsg;

  final emailCtlr = TextEditingController();
  final passCtlr = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailCtlr.dispose();
    passCtlr.dispose();
    super.dispose();
  }

  bool _emailValido(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailCtlr.text.trim(),
          'senha': passCtlr.text,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 200 && data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gn_token', data['token'] ?? '');
        await prefs.setString('gn_tipo', (data['tipo'] ?? 'usuario').toString());
        await prefs.setString('gn_nome', (data['nome'] ?? '').toString());

        if (!mounted) return;
        HapticFeedback.lightImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      } else {
        setState(() {
          errorMsg = data['error']?.toString() ?? 'Falha ao entrar. Verifique seus dados.';
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Não foi possível conectar ao servidor. Verifique sua internet.';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _abrirSiteParaCadastro() async {
    final uri = Uri.parse(siteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _abrirPareamentoCrianca() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildPairingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.shield, color: theme.primaryColor, size: 36),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: 'Guardian', style: TextStyle(color: theme.colorScheme.onSurface)),
                      TextSpan(text: 'Net', style: TextStyle(color: theme.primaryColor)),
                    ],
                  ),
                ),
                const Text('Proteção digital para sua família'),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Bem-vinda de volta', style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Acesse sua conta para continuar'),
                ),
                const SizedBox(height: 20),

                // Campo de e-mail
                TextFormField(
                  controller: emailCtlr,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
                    if (!_emailValido(v)) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: passCtlr,
                  obscureText: obscure,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe sua senha';
                    if (v.length < 6) return 'Senha deve ter ao menos 6 caracteres';
                    return null;
                  },
                ),

                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : _abrirSiteParaCadastro,
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: loading ? null : _fazerLogin,
                    child: loading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Entrar na Conta', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Link para o site (cadastro/pagamento acontece lá, não no app)
                TextButton(
                  onPressed: loading ? null : _abrirSiteParaCadastro,
                  child: const Text.rich(
                    TextSpan(
                      text: 'Novo por aqui? ',
                      children: [
                        TextSpan(
                          text: 'Assine um plano no site',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Acesso da criança via código de pareamento (sem email/senha)
                TextButton(
                  onPressed: loading ? null : _abrirPareamentoCrianca,
                  child: const Text('Sou uma criança, tenho um código'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}