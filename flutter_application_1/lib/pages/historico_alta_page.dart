import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/navbar.dart';

class HistoricoAltaPage extends StatefulWidget {
  const HistoricoAltaPage({super.key});

  @override
  State<HistoricoAltaPage> createState() => _HistoricoAltaPageState();
}

class _HistoricoAltaPageState extends State<HistoricoAltaPage> {
  List<dynamic> historicoAltas = [];
  bool carregando = true;
  bool erro = false;

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  Future<void> carregarHistorico() async {
    try {
      // URL da API Flask (Android Emulator)
      final url = Uri.parse('http://10.0.2.2:5000/altas');
      final resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(resposta.body);
        setState(() {
          historicoAltas = dados;
          carregando = false;
        });
      } else {
        setState(() {
          erro = true;
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        erro = true;
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Altas'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : erro
              ? const Center(
                  child: Text(
                    'Erro ao carregar dados.',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1976D2).withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: historicoAltas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma alta registrada ainda.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: historicoAltas.length,
                          itemBuilder: (context, index) {
                            final alta = historicoAltas[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alta['nome_paciente'] ?? 'Sem nome',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Data da Alta: ${alta['data_alta'] ?? '-'}',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Resumo: ${alta['resumo'] ?? '-'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
      bottomNavigationBar: const NavBar(selectedIndex: 3),
    );
  }
}
