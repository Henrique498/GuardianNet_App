import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../services/ia_service.dart';
import '../theme/app_theme.dart';

enum _AbaAlertas { alertas, testarIa }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertLevel? filtro; // null = "Todos"
  _AbaAlertas aba = _AbaAlertas.alertas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AbaToggle(
          ativo: aba,
          onSelecionar: (a) => setState(() => aba = a),
        ),
        const SizedBox(height: 18),
        if (aba == _AbaAlertas.alertas) _buildAlertas() else const _TestarIaPanel(),
      ],
    );
  }

  Widget _buildAlertas() {
    final all = MockData.alerts;
    final filtered = filtro == null ? all : all.where((a) => a.level == filtro).toList();

    final filtros = <AlertLevel?>[null, AlertLevel.perigo, AlertLevel.atencao, AlertLevel.seguro];
    String rotulo(AlertLevel? f) {
      switch (f) {
        case null:
          return 'Todos';
        case AlertLevel.perigo:
          return 'Perigo';
        case AlertLevel.atencao:
          return 'Atenção';
        case AlertLevel.seguro:
          return 'Seguro';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filtros
                .map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GradientChip(
                label: rotulo(f),
                ativo: filtro == f,
                onTap: () => setState(() => filtro = f),
              ),
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Nenhum alerta neste nível de risco.', style: TextStyle(color: AppColors.brancoDim)),
            ),
          )
        else
          ...filtered.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showAlertDetailSheet(context, a),
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LabelCaps(a.app),
                              const SizedBox(height: 4),
                              Text(a.category,
                                  style: const TextStyle(
                                      fontSize: 14.5, color: AppColors.branco, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        RiskBadge(risk: a.level),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(a.description, style: TextStyle(fontSize: 12.5, color: AppColors.brancoDim, height: 1.4)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Perfil: ${a.child}',
                            style: TextStyle(fontSize: 11, color: AppColors.brancoDim.withOpacity(0.7))),
                        Text(a.time, style: TextStyle(fontSize: 11, color: AppColors.brancoDim.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
      ],
    );
  }
}

/// Toggle "Alertas" / "Testar IA" — pill segmentada no mesmo estilo visual
/// do toggle mensal/anual do site (guardiannet.css .toggle-periodo).
class _AbaToggle extends StatelessWidget {
  final _AbaAlertas ativo;
  final void Function(_AbaAlertas) onSelecionar;

  const _AbaToggle({required this.ativo, required this.onSelecionar});

  Widget _botao(String label, _AbaAlertas valor) {
    final selecionado = ativo == valor;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onSelecionar(valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selecionado ? AppColors.gradienteBrand : null,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selecionado ? AppColors.onGradient : AppColors.brancoDim,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.navy2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borda),
      ),
      child: Row(
        children: [
          _botao('Alertas', _AbaAlertas.alertas),
          _botao('Testar IA', _AbaAlertas.testarIa),
        ],
      ),
    );
  }
}

/// Painel de teste manual da IA — chama /api/ia/analisar e, opcionalmente,
/// /api/ia/aprender para dar feedback sobre o resultado.
class _TestarIaPanel extends StatefulWidget {
  const _TestarIaPanel();

  @override
  State<_TestarIaPanel> createState() => _TestarIaPanelState();
}

class _TestarIaPanelState extends State<_TestarIaPanel> {
  final TextEditingController _controller = TextEditingController();
  bool _carregando = false;
  bool _feedbackEnviado = false;
  String? _erro;
  Map<String, dynamic>? _resultado;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  AlertLevel _nivelParaAlertLevel(String nivel) {
    switch (nivel) {
      case 'perigo':
        return AlertLevel.perigo;
      case 'atencao':
        return AlertLevel.atencao;
      default:
        return AlertLevel.seguro;
    }
  }

  Future<void> _analisar() async {
    final texto = _controller.text.trim();
    if (texto.length < 5) {
      setState(() => _erro = 'Digite uma mensagem com pelo menos 5 caracteres.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
      _resultado = null;
      _feedbackEnviado = false;
    });

    final resultado = await IAService.analisarMensagem(texto);

    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (resultado == null) {
        _erro = 'Não foi possível conectar à IA agora. Se o servidor estava "dormindo", tente de novo em alguns segundos.';
      } else {
        _resultado = resultado;
      }
    });
  }

  Future<void> _ensinar(bool isPredator) async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    // Some a seção de feedback imediatamente ao clicar — não espera a
    // resposta do servidor pra sumir.
    setState(() => _feedbackEnviado = true);

    final resultado = await IAService.aprender(texto, isPredator);
    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obrigado! A IA aprendeu com esse exemplo.')),
      );
    } else if (resultado['erroPlanoNecessario'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ensinar a IA é exclusivo para assinantes (plano Básico ou superior).')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar o feedback agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.azulPastel),
                  const SizedBox(width: 6),
                  LabelCaps('Laboratório de IA'),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Teste como o GuardianNet analisaria uma mensagem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.branco),
              ),
              const SizedBox(height: 6),
              Text(
                'Digite um exemplo de mensagem para ver o nível de risco calculado pela IA (River) e pelo detector de palavras-chave.',
                style: TextStyle(fontSize: 12.5, color: AppColors.brancoDim, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                style: const TextStyle(color: AppColors.branco, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Ex.: "não conta pra ninguém, é nosso segredinho"',
                ),
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                },
              ),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!, style: const TextStyle(color: AppColors.perigo, fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              GradientButton(
                label: 'Analisar mensagem',
                icon: Icons.search_rounded,
                loading: _carregando,
                onPressed: _carregando ? null : _analisar,
              ),
              if (_carregando) ...[
                const SizedBox(height: 10),
                Text(
                  'O servidor pode levar até ~50s para "acordar" (plano gratuito do Render).',
                  style: TextStyle(fontSize: 11, color: AppColors.brancoDim),
                ),
              ],
            ],
          ),
        ),
        if (_resultado != null) ...[
          const SizedBox(height: 16),
          _ResultadoIa(
            resultado: _resultado!,
            nivel: _nivelParaAlertLevel((_resultado!['nivel'] ?? 'seguro').toString()),
            feedbackEnviado: _feedbackEnviado,
            onFeedback: _ensinar,
          ),
        ],
      ],
    );
  }
}

class _ResultadoIa extends StatelessWidget {
  final Map<String, dynamic> resultado;
  final AlertLevel nivel;
  final bool feedbackEnviado;
  final Future<void> Function(bool isPredator) onFeedback;

  const _ResultadoIa({
    required this.resultado,
    required this.nivel,
    required this.feedbackEnviado,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final scoreIa = (resultado['score_ia'] as num?)?.toDouble() ?? 0.0;
    final scorePalavras = resultado['score_palavras_chave'] ?? 0;
    final categorias = (resultado['categorias_detectadas'] as List?) ?? const [];
    final modelo = (resultado['modelo'] ?? '').toString();

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LabelCaps('Resultado da análise'),
              RiskBadge(risk: nivel),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricaMini(
                  label: 'Score da IA',
                  valor: '${(scoreIa * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricaMini(
                  label: 'Palavras-chave',
                  valor: '$scorePalavras pts',
                ),
              ),
            ],
          ),
          if (categorias.isNotEmpty) ...[
            const SizedBox(height: 16),
            LabelCaps('Categorias detectadas'),
            const SizedBox(height: 8),
            ...categorias.map((c) {
              final categoria = (c['categoria'] ?? '').toString().replaceAll('_', ' ');
              final termos = (c['termos'] as List?)?.map((t) => t.toString()).join(', ') ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navy3.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borda),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.branco),
                    ),
                    if (termos.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Termos: $termos', style: TextStyle(fontSize: 11.5, color: AppColors.brancoDim)),
                    ],
                  ],
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'Nenhuma categoria de risco por palavra-chave foi encontrada.',
              style: TextStyle(fontSize: 12.5, color: AppColors.brancoDim),
            ),
          ],
          const SizedBox(height: 14),
          Text('Modelo: $modelo', style: TextStyle(fontSize: 11, color: AppColors.brancoDim.withOpacity(0.7))),
          const SizedBox(height: 18),
          const Divider(color: AppColors.borda, height: 1),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: feedbackEnviado
                ? Row(
              key: const ValueKey('feedback-enviado'),
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.seguro),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Feedback enviado. Obrigado por ajudar a treinar a IA!',
                    style: TextStyle(fontSize: 12.5, color: AppColors.brancoDim),
                  ),
                ),
              ],
            )
                : Column(
              key: const ValueKey('feedback-form'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelCaps('Esse resultado está certo?'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlineButtonCustom(
                        text: 'É risco real',
                        icon: Icons.flag_rounded,
                        color: AppColors.perigo,
                        onPressed: () => onFeedback(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlineButtonCustom(
                        text: 'É seguro',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.seguro,
                        onPressed: () => onFeedback(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Seu feedback ajuda o modelo a aprender (recurso exclusivo para assinantes).',
                  style: TextStyle(fontSize: 11, color: AppColors.brancoDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricaMini extends StatelessWidget {
  final String label;
  final String valor;
  const _MetricaMini({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.navy3.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.branco)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.brancoDim)),
        ],
      ),
    );
  }
}

/// Bottom sheet com o detalhe de UM alerta específico.
///
/// Usado sempre que a origem do toque já sabe QUAL alerta o usuário quer ver
/// (ex.: card de alerta crítico no dashboard, sino de notificações) — nesses
/// casos não faz sentido jogar o usuário numa lista genérica, e sim abrir
/// direto o conteúdo do alerta em questão.
///
/// [onVerTodos], se informado, aparece como ação secundária para quem quiser
/// navegar até a Central de Alertas completa a partir daqui.
Future<void> showAlertDetailSheet(
    BuildContext context,
    AlertItem alerta, {
      VoidCallback? onVerTodos,
    }) {
  AlertsInbox.marcarComoLido(alerta);

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.navy2,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: AppColors.navy3, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelCaps(alerta.app),
                    const SizedBox(height: 4),
                    Text(
                      alerta.category,
                      style: const TextStyle(fontSize: 17, color: AppColors.branco, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RiskBadge(risk: alerta.level),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            alerta.description,
            style: TextStyle(fontSize: 13.5, color: AppColors.brancoDim, height: 1.55),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borda),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Perfil: ${alerta.child}', style: TextStyle(fontSize: 12, color: AppColors.brancoDim)),
                Text(alerta.time, style: TextStyle(fontSize: 12, color: AppColors.brancoDim)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (onVerTodos != null) ...[
            GradientButton(
              label: 'Ver todos os alertas',
              icon: Icons.notifications_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                onVerTodos();
              },
            ),
            const SizedBox(height: 10),
          ],
          OutlineButtonCustom(
            text: 'Fechar',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}