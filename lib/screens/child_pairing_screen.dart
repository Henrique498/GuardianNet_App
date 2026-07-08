import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_shell.dart';

class ChildPairingScreen extends StatefulWidget {
  const ChildPairingScreen({super.key});

  @override
  State<ChildPairingScreen> createState() => _ChildPairingScreenState();
}

class _ChildPairingScreenState extends State<ChildPairingScreen> {
  static const String baseUrl = 'https://proteempreenda.onrender.com/api/pairing';

  final nameCtrl = TextEditingController();
  final List<TextEditingController> digitCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> digitNodes = List.generate(6, (_) => FocusNode());

  bool loading = false;
  String? errorMsg;

  @override
  void dispose() {
    nameCtrl.dispose();
    for (final c in digitCtrls) {
      c.dispose();
    }
    for (final n in digitNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _codigo => digitCtrls.map((c) => c.text).join();

  Future<void> _confirmar() async {
    final nome = nameCtrl.text.trim();
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
      // LOG DE DIAGNÓSTICO: O que o app está tentando enviar
      debugPrint('--- INICIANDO REQUISIÇÃO DE PAREAMENTO ---');
      debugPrint('URL: $baseUrl/redeem');
      debugPrint('Payload enviado: {"codigo": "$codigo", "nome": "$nome"}');

      final resp = await http.post(
        Uri.parse('$baseUrl/redeem'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codigo': codigo, 'nome': nome}),
      );

      // LOG DE DIAGNÓSTICO: Resposta bruta do servidor
      debugPrint('STATUS CODE DO SERVIDOR: ${resp.statusCode}');
      debugPrint('CORPO DA RESPOSTA (RAW BODY): ${resp.body}');
      debugPrint('---------------------------------------');

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
        // Se houver um erro detalhado enviado pelo servidor, ele prioriza. Caso contrário, mostra o texto padrão.
        setState(() {
          errorMsg = data['error']?.toString() ?? 'Código inválido ou expirado. Confira e tente de novo.';
        });
      }
    } catch (e, stackTrace) {
      // LOG DE DIAGNÓSTICO: Se o Flutter falhar antes de bater na API ou der timeout
      debugPrint('ERRO CAPTURADO NO CATCH: $e');
      debugPrint('STACKTRACE DO ERRO: $stackTrace');
      debugPrint('---------------------------------------');

      setState(() => errorMsg = 'Sem conexão ou erro interno: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _digitBox(int index) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 44,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(), // Captura eventos de tecla física/virtual
        onKeyEvent: (KeyEvent event) {
          // Detecta o botão de apagar (Backspace) para voltar o quadradinho caso esteja vazio
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
          keyboardType: TextInputType.text, // Permite visualizar melhor números/letras se a fonte mudar
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            UpperCaseTextFormatter(), // Garante que tudo digitado fique em caixa alta interna
          ],
          maxLength: 1,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: theme.primaryColor.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
          ),
          onChanged: (v) {
            if (v.isNotEmpty && index < 5) {
              digitNodes[index + 1].requestFocus();
            }
            if (errorMsg != null) setState(() => errorMsg = null);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.diversity_1, color: theme.primaryColor, size: 34),
              ),
              const SizedBox(height: 16),
              const Text('Entrar com código', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Peça para seu responsável abrir o app dele\ne gerar um código para você.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Seu nome', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Como podemos te chamar?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.face_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Código de 6 dígitos',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _digitBox),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: loading ? null : _confirmar,
                  child: loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: const Text('Sou um responsável, voltar ao login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Formatador auxiliar para forçar caixa alta se necessário
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}