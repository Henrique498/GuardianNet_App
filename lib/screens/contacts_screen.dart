import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mock_data.dart';
import '../theme/app_theme.dart';

const _grupos = ["Família", "Escola", "Amigos"];

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late List<TrustedContact> contatos;
  String filtro = "Todos";

  @override
  void initState() {
    super.initState();
    contatos = List.from(MockData.contacts);
  }

  void _remover(TrustedContact c) {
    HapticFeedback.mediumImpact();
    setState(() => contatos.remove(c));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contato removido.')));
  }

  void _abrirFormulario() {
    final nomeCtrl = TextEditingController();
    final relacaoCtrl = TextEditingController();
    String grupoNovo = 'Família';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.navy3, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('Novo contato confiável', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                const SizedBox(height: 18),
                LabelCaps('Nome'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nomeCtrl,
                  style: const TextStyle(color: AppColors.branco),
                  decoration: const InputDecoration(hintText: 'Ana Ferreira'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 14),
                LabelCaps('Relação'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: relacaoCtrl,
                  style: const TextStyle(color: AppColors.branco),
                  decoration: const InputDecoration(hintText: 'Avó'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a relação' : null,
                ),
                const SizedBox(height: 14),
                LabelCaps('Grupo'),
                const SizedBox(height: 8),
                Row(
                  children: _grupos
                      .map((g) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GradientChip(
                      label: g,
                      ativo: g == grupoNovo,
                      onTap: () => setModalState(() => grupoNovo = g),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'Salvar contato',
                  icon: Icons.check,
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    HapticFeedback.heavyImpact();
                    setState(() {
                      contatos.insert(
                        0,
                        TrustedContact(
                          name: nomeCtrl.text.trim(),
                          phone: '',
                          relation: relacaoCtrl.text.trim(),
                          category: grupoNovo,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Contato confiável adicionado!')));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiveis = filtro == 'Todos' ? contatos : contatos.where((c) => c.category == filtro).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Todos', ..._grupos]
                .map((g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GradientChip(
                label: g,
                ativo: filtro == g,
                onTap: () => setState(() => filtro = g),
              ),
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _abrirFormulario,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borda, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 16, color: AppColors.azulPastel),
                SizedBox(width: 8),
                Text('Adicionar contato', style: TextStyle(color: AppColors.azulPastel, fontSize: 13.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (visiveis.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.person_add_alt_1_outlined, size: 36, color: AppColors.brancoDim),
                  const SizedBox(height: 10),
                  Text('Nenhum contato em "$filtro"', style: TextStyle(color: AppColors.brancoDim)),
                ],
              ),
            ),
          )
        else
          ...visiveis.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navy2.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borda.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                InitialsAvatar(initials: c.initials, size: 44, solid: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontSize: 13.5, color: AppColors.branco)),
                      Text('${c.relation} · ${c.category}',
                          style: TextStyle(fontSize: 11.5, color: AppColors.brancoDim)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.perigo, size: 20),
                  onPressed: () => _remover(c),
                ),
              ],
            ),
          )),
      ],
    );
  }
}