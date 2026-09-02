import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'home_shell.dart';
import '../theme/app_theme.dart';

enum _Perfil { responsavel, crianca }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String authUrl = 'https://proteempreenda.onrender.com/api/auth';
  static const String pairingUrl = 'https://proteempreenda.onrender.com/api/pairing';
  static const String siteUrl = 'https://proteempreenda.vercel.app/planos.html';

  _Perfil perfil = _Perfil.responsavel;
  bool obscure = true;
  bool loading = false;
  String? errorMsg;

  // ── Responsável ──────────────────────────────────────────────
  final _formKeyResp = GlobalKey<FormState>();
  final emailCtlr = TextEditingController();
  final passCtlr = TextEditingController();

  // ── Criança ──────────────────────────────────────────────────
  final nameCtlr = TextEditingController();
  final List<TextEditingController> digitCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> digitNodes = List.generate(6, (_) => FocusNode());

  String get _codigo => digitCtrls.map((c) => c.text).join();

  @override
  void dispose() {
    emailCtlr.dispose();
    passCtlr.dispose();
    nameCtlr.dispose();
    for (final c in digitCtrls) {
      c.dispose();
    }
    for (final n in digitNodes) {
      n.dispose();
    }
    super.dispose();
  }

  bool _emailValido(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  void _trocarPerfil(_Perfil novo) {
    if (loading) return;
    setState(() {
      perfil = novo;
      errorMsg = null;
    });
  }

  Future<void> _fazerLoginResponsavel() async {
    if (!_formKeyResp.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final resp = await http.post(
        Uri.parse('$authUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailCtlr.text.trim(), 'senha': passCtlr.text}),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 200 && data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gn_token', data['token'] ?? '');
        await prefs.setString('gn_tipo', (data['tipo'] ?? 'usuario').toString());
        await prefs.setString('gn_nome', (data['nome'] ?? '').toString());

        if (!mounted) return;
        HapticFeedback.lightImpact();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell()));
      } else {
        setState(() {
          errorMsg = data['error']?.toString() ?? 'Falha ao entrar. Verifique seus dados.';
        });
      }
    } catch (_) {
      setState(() => errorMsg = 'Não foi possível conectar ao servidor. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _confirmarCrianca() async {
    final nome = nameCtlr.text.trim();
    final codigo = _codigo;

    if (nome.length < 2) {
      setState(() => errorMsg = 'Digite seu nome para continuar.');
      return;
    }
    if (codigo.length != 6) {
      setState(() => errorMsg = 'Digite os 6 números do código.');
      return;
    }

    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final resp = await http.post(
        Uri.parse('$pairingUrl/redeem'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codigo': codigo, 'nome': nome}),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 201 && data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gn_token', data['token'] ?? '');
        await prefs.setString('gn_tipo', 'crianca');
        await prefs.setString('gn_nome', (data['nome'] ?? nome).toString());
        await prefs.setString('gn_responsavel_nome', (data['responsavelNome'] ?? '').toString());

        if (!mounted) return;
        HapticFeedback.mediumImpact();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell()));
      } else {
        setState(() {
          errorMsg = data['error']?.toString() ?? 'Código inválido ou expirado. Confira e tente de novo.';
        });
      }
    } catch (e) {
      setState(() => errorMsg = 'Sem conexão ou erro interno. Tente novamente.');
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

  void _submit() {
    if (perfil == _Perfil.responsavel) {
      _fazerLoginResponsavel();
    } else {
      _confirmarCrianca();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKeyResp,
                child: Column(
                  children: [
                    _Cabecalho(),
                    const SizedBox(height: 28),
                    LabelCaps('Quem está acessando?'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PerfilCard(
                            icon: Icons.verified_user_rounded,
                            label: 'Responsável',
                            ativo: perfil == _Perfil.responsavel,
                            onTap: () => _trocarPerfil(_Perfil.responsavel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PerfilCard(
                            icon: Icons.child_care_rounded,
                            label: 'Criança',
                            ativo: perfil == _Perfil.crianca,
                            onTap: () => _trocarPerfil(_Perfil.crianca),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: perfil == _Perfil.responsavel
                          ? _FormResponsavel(
                        emailCtlr: emailCtlr,
                        passCtlr: passCtlr,
                        obscure: obscure,
                        onToggleObscure: () => setState(() => obscure = !obscure),
                        emailValido: _emailValido,
                        onEsqueciSenha: loading ? null : _abrirSiteParaCadastro,
                      )
                          : _FormCrianca(
                        nameCtlr: nameCtlr,
                        digitCtrls: digitCtrls,
                        digitNodes: digitNodes,
                        onChangedLimpaErro: () {
                          if (errorMsg != null) setState(() => errorMsg = null);
                        },
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.perigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.perigo.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.perigo, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMsg!,
                                style: const TextStyle(color: AppColors.perigo, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    GradientButton(
                      label: perfil == _Perfil.responsavel ? 'Entrar na conta' : 'Conectar dispositivo',
                      icon: perfil == _Perfil.responsavel ? Icons.arrow_forward : Icons.link,
                      loading: loading,
                      onPressed: loading ? null : _submit,
                    ),
                    const SizedBox(height: 18),
                    if (perfil == _Perfil.responsavel)
                      TextButton(
                        onPressed: loading ? null : _abrirSiteParaCadastro,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: AppColors.brancoDim, fontSize: 13),
                            children: [
                              TextSpan(text: 'Novo por aqui? '),
                              TextSpan(
                                text: 'Assine um plano no site',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.azulPastel),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'O monitoramento é transparente e consentido pela criança,\nconforme a Lei 15.211/2025.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.brancoDim, fontSize: 11.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogo(width: 160, height: 90, glow: true),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
            children: const [
              TextSpan(text: 'Guardian', style: TextStyle(color: AppColors.branco)),
              TextSpan(text: 'Net', style: TextStyle(color: AppColors.azulPastel)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Proteção digital inteligente para quem você ama.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.brancoDim, fontSize: 13),
        ),
      ],
    );
  }
}

class _PerfilCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _PerfilCard({required this.icon, required this.label, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: ativo ? AppColors.navy3 : AppColors.navy3.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ativo ? AppColors.azulPastel.withOpacity(0.6) : AppColors.borda),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: ativo ? AppColors.azulPastel : AppColors.brancoDim),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ativo ? AppColors.azulPastel : AppColors.brancoDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormResponsavel extends StatelessWidget {
  final TextEditingController emailCtlr;
  final TextEditingController passCtlr;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool Function(String) emailValido;
  final VoidCallback? onEsqueciSenha;

  const _FormResponsavel({
    required this.emailCtlr,
    required this.passCtlr,
    required this.obscure,
    required this.onToggleObscure,
    required this.emailValido,
    required this.onEsqueciSenha,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: emailCtlr,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          style: const TextStyle(color: AppColors.branco),
          decoration: const InputDecoration(
            labelText: 'E-mail',
            labelStyle: TextStyle(color: AppColors.brancoDim),
            floatingLabelStyle: TextStyle(color: AppColors.azulPastel),
            prefixIcon: Icon(Icons.mail_rounded, color: AppColors.azulPastel, size: 20),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borda)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulPastel)),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
            if (!emailValido(v)) return 'E-mail inválido';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: passCtlr,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          style: const TextStyle(color: AppColors.branco),
          decoration: InputDecoration(
            labelText: 'Senha',
            labelStyle: const TextStyle(color: AppColors.brancoDim),
            floatingLabelStyle: const TextStyle(color: AppColors.azulPastel),
            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.azulPastel, size: 20),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borda)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulPastel)),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.brancoDim),
              onPressed: onToggleObscure,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Informe sua senha';
            if (v.length < 6) return 'Senha deve ter ao menos 6 caracteres';
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onEsqueciSenha,
            child: const Text('Esqueci minha senha', style: TextStyle(color: AppColors.azulPastel, fontSize: 12.5)),
          ),
        ),
      ],
    );
  }
}

class _FormCrianca extends StatelessWidget {
  final TextEditingController nameCtlr;
  final List<TextEditingController> digitCtrls;
  final List<FocusNode> digitNodes;
  final VoidCallback onChangedLimpaErro;

  const _FormCrianca({
    required this.nameCtlr,
    required this.digitCtrls,
    required this.digitNodes,
    required this.onChangedLimpaErro,
  });

  Widget _digitBox(BuildContext context, int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (digitCtrls[index].text.isEmpty && index > 0) {
              digitCtrls[index - 1].clear();
              digitNodes[index - 1].requestFocus();
            }
          }
        },
        child: TextField(
          controller: digitCtrls[index],
          focusNode: digitNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: index == 5 ? TextInputAction.done : TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          maxLength: 1,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.branco),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.navy,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borda),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.azulPastel, width: 2),
            ),
          ),
          onChanged: (v) {
            if (v.isNotEmpty && index < 5) {
              digitNodes[index + 1].requestFocus();
            } else if (v.isEmpty && index > 0) {
              digitNodes[index - 1].requestFocus();
            }
            onChangedLimpaErro();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameCtlr,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: AppColors.branco),
          decoration: const InputDecoration(
            labelText: 'Nome da criança',
            labelStyle: TextStyle(color: AppColors.brancoDim),
            floatingLabelStyle: TextStyle(color: AppColors.azulPastel),
            prefixIcon: Icon(Icons.person_rounded, color: AppColors.azulPastel, size: 20),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borda)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulPastel)),
          ),
        ),
        const SizedBox(height: 16),
        LabelCaps('Código de pareamento'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _digitBox(context, i)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navy.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borda),
          ),
          child: const Text(
            'Você saberá sempre que a proteção estiver ativa. Nada é lido em segredo — '
                'o GuardianNet só avisa seus responsáveis quando encontra algo que pode te machucar.',
            style: TextStyle(color: AppColors.brancoDim, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }
}