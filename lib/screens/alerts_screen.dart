import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../widgets/alert_card.dart';
import '../services/ia_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String filter = "Todos";

  void _abrirModalTesteIA(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text('Testar IA (River)'),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Digite uma mensagem para analisar...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final texto = controller.text.trim();
              if (texto.isEmpty) return;

              final resultado = await IAService.analisarMensagem(texto);
              Navigator.pop(ctx);

              if (resultado != null) {
                final isPredator = resultado['is_predator'] ?? false;
                final score = ((resultado['score_ia'] ?? 0.0) as num) * 100;

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(isPredator ? '⚠️ ALERTA DE RISCO' : '✅ MENSAGEM SEGURA'),
                    content: Text(
                      'Resultado: ${isPredator ? "Risco de Grooming" : "Normal"}\n'
                          'Probabilidade da IA: ${score.toStringAsFixed(1)}%\n'
                          'Modelo: ${resultado['modelo'] ?? 'River'}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      )
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Erro ao conectar com o backend.'),
                  ),
                );
              }
            },
            child: const Text('Analisar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = MockData.alerts;
    final perigo = all.where((a) => a.level == AlertLevel.perigo).length;
    final atencao = all.where((a) => a.level == AlertLevel.atencao).length;
    final seguro = all.where((a) => a.level == AlertLevel.seguro).length;

    List<AlertItem> filtered = all;
    if (filter == "Perigo") filtered = all.where((a) => a.level == AlertLevel.perigo).toList();
    if (filter == "Atenção") filtered = all.where((a) => a.level == AlertLevel.atencao).toList();
    if (filter == "Seguro") filtered = all.where((a) => a.level == AlertLevel.seguro).toList();

    final hoje = filtered.where((a) => a.time.contains("min") || a.time.contains("2h")).toList();
    final ontem = filtered.where((a) => !(a.time.contains("min") || a.time.contains("2h"))).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Histórico de Alertas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              IconButton(
                icon: const Icon(Icons.psychology, color: Color(0xFF3B82F6)),
                tooltip: 'Testar IA',
                onPressed: () => _abrirModalTesteIA(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CountChip(label: "Perigo", count: perigo, color: const Color(0xFFFF5C5C)),
              const SizedBox(width: 8),
              _CountChip(label: "Atenção", count: atencao, color: const Color(0xFFFFC107)),
              const SizedBox(width: 8),
              _CountChip(label: "Seguro", count: seguro, color: const Color(0xFF34C759)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ["Todos", "Perigo", "Atenção", "Seguro"].map((f) {
                final selected = f == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                if (hoje.isNotEmpty) ...[
                  const Text("HOJE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...hoje.map((a) => AlertCard(alert: a, onTap: () => _showDetail(context, a))),
                  const SizedBox(height: 16),
                ],
                if (ontem.isNotEmpty) ...[
                  const Text("ONTEM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...ontem.map((a) => AlertCard(alert: a, onTap: () => _showDetail(context, a))),
                ],
                if (filtered.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("Nenhum alerta nessa categoria."))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, AlertItem a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(a.app),
        content: Text(a.description),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar"))],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label; final int count; final Color color;
  const _CountChip({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text("$count $label", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}