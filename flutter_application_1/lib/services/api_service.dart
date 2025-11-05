import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _baseUrl;
  static const Duration timeout = Duration(seconds: 30);
  
  // 🆕 Lista de IPs possíveis para testar automaticamente
  static const List<String> _possibleIPs = [
    'http://10.0.2.2:5000',        // Emulador Android
    'http://127.0.0.1:5000',       // Localhost
    'http://192.168.1.100:5000',   // Rede comum 192.168.1.x
    'http://192.168.0.100:5000',   // Rede comum 192.168.0.x  
    'http://192.168.1.101:5000',   // Variações comuns
    'http://192.168.1.102:5000',
    'http://10.0.0.186:5000',      // Seu IP atual
    'http://10.0.0.100:5000',      // Variações da sua rede
    'http://10.0.0.101:5000',
  ];

  // Headers padrão
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // 🆕 NOVO: Descobrir URL da API automaticamente
  static Future<String?> descobrirURL() async {
    print('🔍 Descobrindo URL da API automaticamente...');
    
    // Testar lista de IPs possíveis
    for (String url in _possibleIPs) {
      try {
        print('🧪 Testando: $url');
        if (await _testarURL(url)) {
          print('✅ API encontrada em: $url');
          _baseUrl = url;
          return url;
        }
      } catch (e) {
        print('❌ Falhou: $url - ${e.toString().substring(0, 50)}...');
        continue;
      }
    }
    
    print('❌ Nenhuma API encontrada em nenhum IP testado');
    return null;
  }

  // 🆕 NOVO: Testar se uma URL específica está funcionando
  static Future<bool> _testarURL(String url) async {
    try {
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: _headers,
      ).timeout(Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 🆕 NOVO: Configurar URL customizada manualmente
  static void setCustomURL(String url) {
    _baseUrl = url;
    print('💾 URL customizada definida: $url');
  }

  // 🆕 NOVO: Getter para URL base com descoberta automática
  static Future<String> get baseUrl async {
    if (_baseUrl == null) {
      print('🔄 URL não definida, iniciando descoberta...');
      _baseUrl = await descobrirURL();
      
      if (_baseUrl == null) {
        print('⚠️ Usando URL padrão como fallback');
        _baseUrl = 'http://10.0.2.2:5000'; // Fallback para emulador
      }
    }
    return _baseUrl!;
  }

  // 🆕 NOVO: Forçar nova descoberta de URL
  static Future<String?> redescobrir() async {
    _baseUrl = null;
    return await descobrirURL();
  }

  // 🆕 NOVO: Obter informações de rede da API
  static Future<Map<String, dynamic>?> obterInfoRede() async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/network-info'),
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('❌ Erro ao obter info de rede: $e');
    }
    return null;
  }

  // Método genérico para requisições HTTP
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    final url = await baseUrl;
    final uri = Uri.parse('$url$endpoint');
    
    print('🌐 Fazendo requisição: $method $uri');
    
    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: data != null ? jsonEncode(data) : null,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: data != null ? jsonEncode(data) : null,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers).timeout(timeout);
          break;
        default:
          throw Exception('Método HTTP não suportado: $method');
      }

      print('📊 Resposta: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ Erro na requisição: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===============================
  // MÉTODOS DE PACIENTES
  // ===============================
  
  static Future<Map<String, dynamic>> criarPaciente(Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest('POST', '/pacientes', data: data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Erro ao criar paciente');
      }
    } catch (e) {
      throw Exception('Falha ao cadastrar paciente: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> listarPacientes() async {
    try {
      final response = await _makeRequest('GET', '/pacientes');
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao listar pacientes');
      }
    } catch (e) {
      throw Exception('Falha ao carregar pacientes: $e');
    }
  }

  static Future<Map<String, dynamic>> buscarPaciente(int id) async {
    try {
      final response = await _makeRequest('GET', '/pacientes/$id');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Paciente não encontrado');
      }
    } catch (e) {
      throw Exception('Falha ao buscar paciente: $e');
    }
  }

  // ===============================
  // MÉTODOS DE PROTOCOLO
  // ===============================
  
  static Future<Map<String, dynamic>> criarProtocolo(Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest('POST', '/protocolos', data: data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Erro ao salvar protocolo');
      }
    } catch (e) {
      throw Exception('Falha ao salvar protocolo: $e');
    }
  }

  static Future<Map<String, dynamic>> buscarProtocolo(int pacienteId) async {
    try {
      final response = await _makeRequest('GET', '/protocolos/$pacienteId');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Protocolo não encontrado');
      }
    } catch (e) {
      throw Exception('Falha ao buscar protocolo: $e');
    }
  }

  // ===============================
  // MÉTODOS DE PRESCRIÇÃO
  // ===============================
  
  static Future<Map<String, dynamic>> criarPrescricao(Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest('POST', '/prescricoes', data: data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao criar prescrição');
      }
    } catch (e) {
      throw Exception('Falha ao salvar prescrição: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> listarPrescricoes(int pacienteId) async {
    try {
      final response = await _makeRequest('GET', '/prescricoes/$pacienteId');
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao listar prescrições');
      }
    } catch (e) {
      throw Exception('Falha ao carregar prescrições: $e');
    }
  }

  // ===============================
  // MÉTODOS DE ACOMPANHAMENTO
  // ===============================
  
  static Future<Map<String, dynamic>> registrarAcompanhamento(Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest('POST', '/acompanhamentos', data: data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao registrar acompanhamento');
      }
    } catch (e) {
      throw Exception('Falha ao registrar acompanhamento: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> listarAcompanhamentos(int pacienteId) async {
    try {
      final response = await _makeRequest('GET', '/acompanhamentos/$pacienteId');
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao listar acompanhamentos');
      }
    } catch (e) {
      throw Exception('Falha ao carregar acompanhamentos: $e');
    }
  }

  // ===============================
  // MÉTODOS DE ALTA
  // ===============================
  
  static Future<Map<String, dynamic>> registrarAlta(Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest('POST', '/altas', data: data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao registrar alta');
      }
    } catch (e) {
      throw Exception('Falha ao registrar alta: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> listarAltas(int pacienteId) async {
    try {
      final response = await _makeRequest('GET', '/altas/$pacienteId');
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao listar altas');
      }
    } catch (e) {
      throw Exception('Falha ao carregar altas: $e');
    }
  }

  // ===============================
  // MÉTODOS UTILITÁRIOS
  // ===============================
  
  // 🆕 NOVO: Teste com descoberta automática
  static Future<bool> testarConexaoComDescoberta() async {
    try {
      String? url = await descobrirURL();
      return url != null;
    } catch (e) {
      print('❌ Erro no teste com descoberta: $e');
      return false;
    }
  }

  // Método original de teste (mantido para compatibilidade)
  static Future<bool> testarConexao() async {
    try {
      final response = await _makeRequest('GET', '/health');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erro no teste de conexão: $e');
      
      // Se falhar, tentar redescobrir
      print('🔄 Tentando redescobrir API...');
      String? novaUrl = await redescobrir();
      if (novaUrl != null) {
        final response = await _makeRequest('GET', '/health');
        return response.statusCode == 200;
      }
      
      return false;
    }
  }

  // 🆕 NOVO: Obter status detalhado da conexão
  static Future<Map<String, dynamic>> obterStatusDetalhado() async {
    try {
      final url = await baseUrl;
      final response = await _makeRequest('GET', '/health');
      
      return {
        'conectado': response.statusCode == 200,
        'url': url,
        'status_code': response.statusCode,
        'resposta': jsonDecode(response.body),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'conectado': false,
        'url': _baseUrl ?? 'não_definida',
        'erro': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // 🆕 NOVO: Limpar URL configurada
  static void limparConfiguracoes() {
    _baseUrl = null;
    print('🗑️ URL limpa - será redescoberta na próxima requisição');
  }

  static Future<Map<String, dynamic>?> buscarAlta(int pacienteId) async {
  try {
    final response = await _makeRequest('GET', '/altas/$pacienteId');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return data.first;
      } else if (data is Map<String, dynamic>) {
        return data;
      } else {
        return null;
      }
    } else {
      throw Exception('Erro ao buscar alta (status ${response.statusCode})');
    }
  } catch (e) {
    throw Exception('Falha ao buscar alta: $e');
  }
}

}



