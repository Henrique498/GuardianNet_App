import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_data.dart';
import '../widgets/contact_card.dart';
import '../widgets/alert_card.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onVerTodosAlertas;

  const DashboardScreen({super.key, this.onVerTodosAlertas});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedCategory = 'Família';
  late List<TrustedContact> contacts;
  String nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    contacts = List.from(MockData.contacts);
    _carregarNome();
  }

  Future<void> _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('gn_nome') ?? '';
    if (mounted) setState(() => nomeUsuario = nome);
  }

  void addContact(String name, String phone, String relation) {
    HapticFeedback.heavyImpact();
    setState(() {
      contacts.add(TrustedContact(
          name: name, phone: phone, relation: relation, category: selectedCategory));
    });
  }

  void showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 16),
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
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Novo Contato ($selectedCategory)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.1)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nome completo", prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? "Informe o nome" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "WhatsApp / Telefone", prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => v!.isEmpty ? "Informe o telefone" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: relationCtrl,
                decoration: const InputDecoration(labelText: "Relação (ex: Mãe, Tio)", prefixIcon: Icon(Icons.label_outline)),
                validator: (v) => v!.isEmpty ? "Informe o grau de parentesco" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    addContact(nameCtrl.text, phoneCtrl.text, relationCtrl.text);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Adicionar à Lista'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetail(AlertItem a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(a.app),
          ],
        ),
        content: Text(a.description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Entendido")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = contacts.where((c) => c.category == selectedCategory).toList();
    final alertasPerigo = MockData.alerts.where((a) => a.level == AlertLevel.perigo).toList();
    final primeiroNome = nomeUsuario.isEmpty ? '' : nomeUsuario.split(' ').first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primeiroNome.isEmpty ? "Olá! 👋" : "Olá, $primeiroNome 👋",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5),
                ),
                Text("Aqui está o resumo de hoje", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurfaceVariant),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Configurações do painel em desenvolvimento.")),
                );
              },
            )
          ],
        ),
        const SizedBox(height: 20),

        if (alertasPerigo.isNotEmpty) ...[
          InkWell(
            onTap: () => _showAlertDetail(alertasPerigo.first),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alertasPerigo.length == 1
                          ? "1 alerta crítico precisa de atenção imediata"
                          : "${alertasPerigo.length} alertas críticos precisam de atenção",
                      style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onErrorContainer),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Cards de Status Limpos
        Row(
          children: [
            _StatCard(icon: Icons.people_outline, value: "${contacts.length}", label: "Contatos"),
            const SizedBox(width: 12),
            _StatCard(icon: Icons.notifications_none, value: "${MockData.alerts.length}", label: "Alertas Hoje"),
          ],
        ),
        const SizedBox(height: 24),

        // Cabeçalho de Contatos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CONTATOS CONFIÁVEIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
            TextButton.icon(
              onPressed: showAddDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Adicionar"),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ["Família", "Escola", "Amigos"].map((cat) {
              final selected = cat == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    setState(() => selectedCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.person_add_alt_1_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('Nenhum contato em "$selectedCategory"', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final c = filtered[idx];
              return ContactCard(
                contact: c,
                onDelete: () {
                  HapticFeedback.mediumImpact();
                  setState(() => contacts.remove(c));
                },
              );
            },
          ),
        const SizedBox(height: 20),

        // Alertas Recentes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ALERTAS RECENTES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
            if (widget.onVerTodosAlertas != null)
              TextButton(onPressed: widget.onVerTodosAlertas, child: const Text("Ver todos")),
          ],
        ),
        const SizedBox(height: 8),
        ...MockData.alerts.take(3).map((a) => AlertCard(alert: a, onTap: () => _showAlertDetail(a))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String value, label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
                Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            )
          ],
        ),
      ),
    );
  }
}