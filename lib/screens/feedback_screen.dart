import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../theme/app_theme.dart';

class FeedbackEntry {
  int rating;
  String comment;
  String topic;
  String status;
  String date;
  FeedbackEntry({required this.rating, required this.comment, required this.topic, this.status = 'Enviado', required this.date});
}

const _topicos = [
  {'id': 'alertas', 'label': 'Alertas'},
  {'id': 'pareamento', 'label': 'Pareamento'},
  {'id': 'contatos', 'label': 'Contatos'},
  {'id': 'plano', 'label': 'Plano'},
  {'id': 'outro', 'label': 'Outro'},
];

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int rating = 0;
  String topico = 'alertas';
  final commentCtrl = TextEditingController();
  final List<FeedbackEntry> entries = [];

  void submit() {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha uma nota de 1 a 5 estrelas.')));
      return;
    }
    if (commentCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escreva um pouco mais sobre sua experiência.')));
      return;
    }
    setState(() {
      entries.insert(
        0,
        FeedbackEntry(
          rating: rating,
          comment: commentCtrl.text.trim(),
          topic: _topicos.firstWhere((t) => t['id'] == topico)['label']!,
          status: 'Em análise',
          date: 'Agora',
        ),
      );
      rating = 0;
      commentCtrl.clear();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Feedback enviado. Obrigado por ajudar a melhorar!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.azulPastel),
                  const SizedBox(width: 6),
                  LabelCaps('Sua opinião'),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Como está sua experiência?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.branco)),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (i) {
                  final n = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => rating = n),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.navy3.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          n <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 20,
                          color: n <= rating ? AppColors.verdePastel : AppColors.brancoDim,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              LabelCaps('Sobre o que é'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _topicos
                    .map((t) => GradientChip(
                  label: t['label']!,
                  ativo: topico == t['id'],
                  onTap: () => setState(() => topico = t['id']!),
                ))
                    .toList(),
              ),
              const SizedBox(height: 22),
              LabelCaps('Mensagem'),
              const SizedBox(height: 8),
              TextField(
                controller: commentCtrl,
                maxLines: 5,
                style: const TextStyle(color: AppColors.branco, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Conte o que funcionou bem, o que atrapalhou ou o que você gostaria de ver no app.',
                ),
              ),
              const SizedBox(height: 18),
              GradientButton(label: 'Enviar feedback', icon: Icons.send_rounded, onPressed: submit),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Meus envios', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
        const SizedBox(height: 12),
        ...[...entries, ...MockData.feedbackHistory.map((h) => FeedbackEntry(
          rating: h.rating,
          comment: h.message,
          topic: h.topic,
          status: h.status,
          date: h.date,
        ))]
            .map((e) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.topic,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.branco)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.navy3, borderRadius: BorderRadius.circular(999)),
                      child: Text(e.status, style: TextStyle(fontSize: 10.5, color: AppColors.brancoDim)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(
                      5,
                          (i) => Icon(
                        i < e.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14,
                        color: i < e.rating ? AppColors.verdePastel : AppColors.brancoDim.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(e.date, style: TextStyle(fontSize: 11, color: AppColors.brancoDim)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(e.comment, style: TextStyle(fontSize: 12.5, color: AppColors.brancoDim, height: 1.4)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}