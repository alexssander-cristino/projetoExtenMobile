import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator

  static Future<void> criarPaciente(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/pacientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw Exception('Erro ao criar paciente');
    }
  }
}
