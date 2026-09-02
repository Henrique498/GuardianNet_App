import 'package:flutter/foundation.dart';

enum AlertLevel { seguro, atencao, perigo }

class Parent {
  final String name, fullName, email, initials;
  const Parent({required this.name, required this.fullName, required this.email, required this.initials});
}

class ChildProfile {
  final String id, name, device, status;
  final int age;
  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.device,
    required this.status,
  });
}

class TrustedContact {
  String name, phone, relation, category;
  TrustedContact({required this.name, required this.phone, required this.relation, required this.category});

  String get initials {
    final partes = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }
}

class AlertItem {
  String child, app, category, description, time;
  AlertLevel level;
  bool lida;
  AlertItem({
    required this.child,
    required this.app,
    required this.category,
    required this.description,
    required this.time,
    required this.level,
    this.lida = false,
  });
}

class PlanInfo {
  final String name, price, cycle, renewal;
  final int seats, used;
  final List<String> features;
  const PlanInfo({
    required this.name,
    required this.price,
    required this.cycle,
    required this.renewal,
    required this.seats,
    required this.used,
    required this.features,
  });
}

class FeedbackHistoryItem {
  final String topic, date, status, message;
  final int rating;
  const FeedbackHistoryItem({
    required this.topic,
    required this.date,
    required this.status,
    required this.message,
    required this.rating,
  });
}

class MockData {
  static const parent = Parent(
    name: "Camila",
    fullName: "Camila Ferreira",
    email: "camila.ferreira@email.com",
    initials: "CF",
  );

  static const children = [
    ChildProfile(id: "c1", name: "Lucas", age: 11, device: "Android · Moto G54", status: "Protegido"),
    ChildProfile(id: "c2", name: "Sofia", age: 9, device: "iPhone SE", status: "Protegido"),
  ];

  static List<TrustedContact> contacts = [
    TrustedContact(name: "Ana Ferreira", phone: "+55 11 98765-0001", relation: "Avó", category: "Família"),
    TrustedContact(name: "Rafael Ferreira", phone: "+55 11 98765-0002", relation: "Pai", category: "Família"),
    TrustedContact(name: "Prof. Marina", phone: "+55 11 96543-0004", relation: "Coordenadora", category: "Escola"),
    TrustedContact(name: "Beatriz", phone: "+55 11 94321-0006", relation: "Colega de turma", category: "Amigos"),
    TrustedContact(name: "Tio Paulo", phone: "+55 11 93210-0007", relation: "Tio", category: "Família"),
  ];

  static List<AlertItem> alerts = [
    AlertItem(
      child: "Lucas",
      app: "WhatsApp",
      category: "Possível aliciamento",
      description: "Contato desconhecido pediu para conversar em outro app e manter segredo.",
      time: "Hoje, 14:32",
      level: AlertLevel.perigo,
    ),
    AlertItem(
      child: "Sofia",
      app: "Roblox",
      category: "Cyberbullying",
      description: "Mensagens repetidas com ofensas em um grupo de jogo.",
      time: "Hoje, 11:05",
      level: AlertLevel.atencao,
    ),
    AlertItem(
      child: "Lucas",
      app: "Instagram",
      category: "Conteúdo impróprio",
      description: "Link suspeito enviado por perfil sem histórico de conversa.",
      time: "Ontem, 20:48",
      level: AlertLevel.atencao,
    ),
    AlertItem(
      child: "Sofia",
      app: "WhatsApp",
      category: "Conversa saudável",
      description: "Nenhum risco identificado nas últimas 24 horas.",
      time: "Ontem, 18:20",
      level: AlertLevel.seguro,
    ),
  ];

  static const plan = PlanInfo(
    name: "GuardianNet Família",
    price: "R\$ 29,90",
    cycle: "por mês",
    renewal: "12 de setembro de 2026",
    seats: 4,
    used: 2,
    features: [
      "Monitoramento com IA em tempo real",
      "Até 4 perfis infantis",
      "Alertas instantâneos por push e e-mail",
      "Relatórios semanais de comportamento",
      "Contatos confiáveis ilimitados",
    ],
  );

  static const feedbackHistory = [
    FeedbackHistoryItem(
      topic: "Alertas",
      rating: 5,
      date: "28 jul 2026",
      status: "Respondido",
      message: "Os alertas de risco alto chegam bem rápido. Só senti falta de um resumo semanal.",
    ),
    FeedbackHistoryItem(
      topic: "Pareamento",
      rating: 4,
      date: "11 jul 2026",
      status: "Em análise",
      message: "O código expirou antes da criança digitar. Poderia durar mais tempo.",
    ),
  ];
}

/// Controla o estado de "alerta crítico não visto" de forma global e reativa.
///
/// Usa [ValueNotifier] em vez de propagar `setState` manualmente entre
/// widgets desconectados (sino no home_shell, card no dashboard, lista de
/// alertas) — qualquer um deles pode marcar um alerta como lido, e o sino
/// atualiza sozinho via [ValueListenableBuilder].
class AlertsInbox {
  static final ValueNotifier<bool> hasUnreadCritical = ValueNotifier<bool>(_calcular());

  static bool _calcular() {
    return MockData.alerts.any((a) => a.level == AlertLevel.perigo && !a.lida);
  }

  /// Marca um alerta como visto. Se ele era o único crítico não lido,
  /// a bolinha do sino some.
  static void marcarComoLido(AlertItem alerta) {
    if (alerta.lida) return;
    alerta.lida = true;
    hasUnreadCritical.value = _calcular();
  }

  /// Chame isto quando um NOVO alerta crítico chegar via API (futuramente),
  /// para reacender a bolinha do sino.
  static void notificarNovoAlerta() {
    hasUnreadCritical.value = _calcular();
  }
}