import 'dart:convert';
import 'package:http/http.dart' as http;

class IAService {
  static const String apiUrl = 'https://proteempreenda.onrender.com/api/ia/analisar';

  static Future<Map<String, dynamic>?> analisarMensagem(String texto) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'texto': texto}),
      ).timeout(const Duration(seconds: 60)); // dá tempo do Render "acordar" (free tier)

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
}