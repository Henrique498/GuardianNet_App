import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IAService {
  static const String analisarUrl = 'https://proteempreenda.onrender.com/api/ia/analisar';
  static const String aprenderUrl = 'https://proteempreenda.onrender.com/api/ia/aprender';

  static Future<String> _obterToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gn_token') ?? '';
  }

  static Future<Map<String, dynamic>?> analisarMensagem(String texto) async {
    try {
      final token = await _obterToken();
      final response = await http.post(
        Uri.parse(analisarUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'texto': texto}),
      ).timeout(const Duration(seconds: 60)); // dá tempo do Render "acordar"

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Resposta do Render (Status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Erro ao conectar no Render: $e');
    }
    return null;
  }

  /// Ensina o modelo. Só funciona para usuários com plano pago ativo —
  /// se o backend responder 403, [erroPlanoNecessario] vem true.
  static Future<Map<String, dynamic>> aprender(String texto, bool isPredator) async {
    try {
      final token = await _obterToken();
      final response = await http.post(
        Uri.parse(aprenderUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'texto': texto, 'is_predator': isPredator}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {'sucesso': true, 'erroPlanoNecessario': false};
      }
      if (response.statusCode == 403) {
        return {'sucesso': false, 'erroPlanoNecessario': true};
      }
      return {'sucesso': false, 'erroPlanoNecessario': false};
    } catch (e) {
      print('Erro ao enviar aprendizado: $e');
      return {'sucesso': false, 'erroPlanoNecessario': false};
    }
  }
}